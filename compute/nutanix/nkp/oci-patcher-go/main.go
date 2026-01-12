package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"
)

var (
	ociRepoGVK = schema.GroupVersionKind{
		Group:   "source.toolkit.fluxcd.io",
		Version: "v1beta2",
		Kind:    "OCIRepository",
	}
	ociRepoGVKv1 = schema.GroupVersionKind{
		Group:   "source.toolkit.fluxcd.io",
		Version: "v1",
		Kind:    "OCIRepository",
	}
)

type OCIRepositoryReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

func (r *OCIRepositoryReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := ctrl.Log.WithValues("ocirepository", req.NamespacedName)

	// Try v1 first, then v1beta2
	obj := &unstructured.Unstructured{}
	obj.SetGroupVersionKind(ociRepoGVKv1)
	if err := r.Get(ctx, req.NamespacedName, obj); err != nil {
		obj.SetGroupVersionKind(ociRepoGVK)
		if err := r.Get(ctx, req.NamespacedName, obj); err != nil {
			return ctrl.Result{}, client.IgnoreNotFound(err)
		}
	}

	insecure, insecureFound, err := unstructured.NestedBool(obj.Object, "spec", "insecure")
	if err != nil {
		return ctrl.Result{}, err
	}

	_, hasCertRef, _ := unstructured.NestedFieldNoCopy(obj.Object, "spec", "certSecretRef")

	// Check if we need to patch or trigger
	needsPatch := !insecureFound || !insecure || hasCertRef

	// Also trigger if the status is Failed
	isFailed := false
	conditions, found, _ := unstructured.NestedSlice(obj.Object, "status", "conditions")
	if found {
		for _, c := range conditions {
			cond, ok := c.(map[string]interface{})
			if !ok {
				continue
			}
			if cond["type"] == "Ready" && cond["status"] == "False" {
				isFailed = true
				break
			}
		}
	}

	if needsPatch || isFailed {
		// Capture original state for patching BEFORE any modifications
		repoPatch := client.MergeFrom(obj.DeepCopy())
		modified := false

		if hasCertRef {
			log.Info("Removing spec.certSecretRef to honor insecure flag")
			unstructured.RemoveNestedField(obj.Object, "spec", "certSecretRef")
			modified = true
		}
		if !insecureFound || !insecure {
			log.Info("Enforcing spec.insecure: true")
			if err := unstructured.SetNestedField(obj.Object, true, "spec", "insecure"); err != nil {
				return ctrl.Result{}, fmt.Errorf("failed to set insecure: %w", err)
			}
			modified = true
		}

		if isFailed && !modified {
			log.Info("Retriggering failed OCIRepository")
		}

		// Add reconciliation trigger to OCIRepository
		now := time.Now()
		requestedAt := now.Format(time.RFC3339)
		annotations := obj.GetAnnotations()
		if annotations == nil {
			annotations = make(map[string]string)
		}

		// Loop prevention: Only trigger if not done in the last 2 minutes
		shouldTrigger := true
		if lastReqStr, ok := annotations["reconcile.fluxcd.io/requestedAt"]; ok {
			lastReq, err := time.Parse(time.RFC3339, lastReqStr)
			if err == nil && now.Sub(lastReq) < 2*time.Minute {
				shouldTrigger = false
				log.Info("Skipping trigger (already requested recently)", "lastRequest", lastReqStr)
			}
		}

		if shouldTrigger {
			log.Info("Applying requestedAt annotation", "time", requestedAt)
			annotations["reconcile.fluxcd.io/requestedAt"] = requestedAt
			obj.SetAnnotations(annotations)
			modified = true
		}

		if modified {
			if err := r.Patch(ctx, obj, repoPatch); err != nil {
				log.Error(err, "Failed to patch OCIRepository")
				return ctrl.Result{}, err
			}
			log.Info("Successfully patched/triggered OCIRepository")
		}
		// Trigger all dependent HelmReleases
		log.Info("Listing HelmReleases to trigger dependents")
		hrs := &unstructured.UnstructuredList{}

		// Try v2 first, then v2beta1
		hrs.SetGroupVersionKind(schema.GroupVersionKind{
			Group:   "helm.toolkit.fluxcd.io",
			Version: "v2",
			Kind:    "HelmReleaseList",
		})
		if err := r.List(ctx, hrs); err != nil {
			log.Info("v2 HelmRelease not found, falling back to v2beta1")
			hrs.SetGroupVersionKind(schema.GroupVersionKind{
				Group:   "helm.toolkit.fluxcd.io",
				Version: "v2beta1",
				Kind:    "HelmReleaseList",
			})
			if err := r.List(ctx, hrs); err != nil {
				log.Error(err, "Failed to list HelmReleases (v2 and v2beta1)")
				return ctrl.Result{}, nil // Continue anyway
			}
		}

		triggeredCount := 0
		for _, hr := range hrs.Items {
			sourceName := ""
			sourceKind := ""
			sourceNamespace := ""

			// Try spec.chartRef (newer Flux)
			chartRef, found, _ := unstructured.NestedMap(hr.Object, "spec", "chartRef")
			if found {
				sourceName, _, _ = unstructured.NestedString(chartRef, "name")
				sourceKind, _, _ = unstructured.NestedString(chartRef, "kind")
				sourceNamespace, _, _ = unstructured.NestedString(chartRef, "namespace")
			} else {
				// Fallback to spec.chart.spec.sourceRef (older Flux)
				sourceRef, found, _ := unstructured.NestedMap(hr.Object, "spec", "chart", "spec", "sourceRef")
				if found {
					sourceName, _, _ = unstructured.NestedString(sourceRef, "name")
					sourceKind, _, _ = unstructured.NestedString(sourceRef, "kind")
					sourceNamespace, _, _ = unstructured.NestedString(sourceRef, "namespace")
				}
			}

			if sourceName == "" {
				continue
			}

			if sourceNamespace == "" {
				sourceNamespace = hr.GetNamespace()
			}

			if sourceKind == "OCIRepository" && sourceName == req.Name && sourceNamespace == req.Namespace {
				triggeredCount++
				log.Info("Triggering dependent HelmRelease", "name", hr.GetName(), "namespace", hr.GetNamespace())

				hrPatch := client.MergeFrom(hr.DeepCopy())
				hrAnnotations := hr.GetAnnotations()
				if hrAnnotations == nil {
					hrAnnotations = make(map[string]string)
				}

				hrAnnotations["reconcile.fluxcd.io/requestedAt"] = requestedAt
				hr.SetAnnotations(hrAnnotations)

				if err := r.Patch(ctx, &hr, hrPatch); err != nil {
					log.Error(err, "Failed to trigger HelmRelease", "name", hr.GetName())
				}
			}
		}
		log.Info("Finished triggering dependent HelmReleases", "count", triggeredCount)
	}

	return ctrl.Result{}, nil
}

func main() {
	ctrl.SetLogger(zap.New(zap.UseDevMode(true)))

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme: runtime.NewScheme(),
	})
	if err != nil {
		fmt.Printf("unable to start manager: %v\n", err)
		os.Exit(1)
	}

	reconciler := &OCIRepositoryReconciler{
		Client: mgr.GetClient(),
		Scheme: mgr.GetScheme(),
	}

	// Watch OCIRepository v1 (Flux v2 defaults to v1 in newer versions)
	u := &unstructured.Unstructured{}
	u.SetGroupVersionKind(ociRepoGVKv1)

	if err = ctrl.NewControllerManagedBy(mgr).
		For(u).
		Named("oci-patcher").
		Complete(reconciler); err != nil {
		fmt.Printf("unable to create controller for v1: %v. Falling back to v1beta2...\n", err)

		u.SetGroupVersionKind(ociRepoGVK)
		if err = ctrl.NewControllerManagedBy(mgr).
			For(u).
			Named("oci-patcher").
			Complete(reconciler); err != nil {
			fmt.Printf("unable to create controller for v1beta2: %v\n", err)
			os.Exit(1)
		}
	}

	fmt.Println("Starting OCI Patcher Go Operator...")
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		fmt.Printf("problem running manager: %v\n", err)
		os.Exit(1)
	}
}
