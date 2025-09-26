terraform {
  required_version = ">= 1.3.0"
}

locals {
  nims = merge(
    var.topic_control_nim.enabled ? {
      topic_control = {
        name  = "topic-control-nim"
        image = var.topic_control_nim.image
        tag   = var.topic_control_nim.tag
      }
    } : {},
    var.content_safety_nim.enabled ? {
      content_safety = {
        name  = "content-safety-nim"
        image = var.content_safety_nim.image
        tag   = var.content_safety_nim.tag
      }
    } : {},
    var.jailbreak_detection_nim.enabled ? {
      jailbreak_detection = {
        name  = "jailbreak-detection-nim"
        image = var.jailbreak_detection_nim.image
        tag   = var.jailbreak_detection_nim.tag
      }
    } : {}
  )
}
