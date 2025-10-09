locals {
  # Encode the APIs configuration as JSON to pass to the k6 script
  apis_json = jsonencode([for api in var.apis : {
    host   = api.host
    models = api.models
  }])
  
  # Encode users configuration
  users_json = jsonencode([for user in var.users : {
    username = user.username
    password = user.password
  }])
}

resource "kubectl_manifest" "aigateway_traffic_configmap" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: aigateway-traffic
    data:
      load.js: |
        import http from 'k6/http';
        import { sleep } from 'k6';
        import { randomItem, randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

        // Configuration - loaded from Terraform variables
        const APIS = JSON.parse('${replace(local.apis_json, "'", "\\'")}');
        const USERS = JSON.parse('${replace(local.users_json, "'", "\\'")}');
        const KEYCLOAK_URL = '${var.keycloak_url}';
        const CLIENT_ID = '${var.keycloak_client_id}';
        const CLIENT_SECRET = '${var.keycloak_client_secret}';
        const MIN_MESSAGES = ${var.min_messages_per_conversation};
        const MAX_MESSAGES = ${var.max_messages_per_conversation};
        
        // Traefik service URL
        const TRAEFIK_URL = 'http://traefik.traefik.svc:80/v1/chat/completions';
        
        // Global variable to store user tokens
        let USER_TOKENS = {};

        // System prompts
        const SYSTEM_PROMPTS = [
          "You are a helpful assistant.",
          "You are a knowledgeable AI assistant.",
          "You are a friendly AI that provides concise answers.",
          "You are an expert in various subjects."
        ];

        // Categories of questions to demonstrate semantic caching
        const QUESTION_CATEGORIES = {
          // Each category contains variations of the same question
          capital: [
            "What is the capital of France?",
            "Can you tell me the capital city of France?",
            "Which city serves as France's capital?",
            "I'd like to know the capital of France, please.",
            "France's capital city is what?"
          ],
          quantum: [
            "Explain quantum computing in simple terms.",
            "How would you describe quantum computing to a beginner?",
            "Can you break down quantum computing for me?",
            "I need a simple explanation of quantum computing.",
            "What's quantum computing all about?"
          ],
          aiBenefits: [
            "What are the main benefits of artificial intelligence?",
            "How can artificial intelligence be beneficial?",
            "What advantages does AI offer?",
            "In what ways is artificial intelligence helpful?",
            "What are the pros of AI technology?"
          ],
          blockchain: [
            "How does blockchain technology work?",
            "Can you explain how blockchain functions?",
            "What's the working principle behind blockchain?",
            "How would you describe blockchain technology?",
            "Explain the mechanism of blockchain."
          ],
          relativity: [
            "Explain the theory of relativity.",
            "What is Einstein's theory of relativity?",
            "Can you describe the concept of relativity?",
            "How would you explain the theory of relativity?",
            "What does the theory of relativity state?"
          ],
          programming: [
            "What are the best programming languages to learn in 2025?",
            "Which programming languages should I learn this year?",
            "What are the top programming languages right now?",
            "Can you recommend programming languages to learn in 2025?",
            "What coding languages are most in demand currently?"
          ]
        };

        // Flatten all questions for random selection
        const ALL_QUESTIONS = Object.values(QUESTION_CATEGORIES).flat();

        // Setup function - fetch JWT tokens for all users
        export function setup() {
          console.log('Setup: Fetching JWT tokens for all users...');
          const tokens = {};
          
          USERS.forEach(user => {
            const payload = {
              client_id: CLIENT_ID,
              grant_type: 'password',
              client_secret: CLIENT_SECRET,
              scope: 'openid',
              username: user.username,
              password: user.password
            };

            const params = {
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
            };

            const response = http.post(
              KEYCLOAK_URL,
              Object.keys(payload)
                .map(key => encodeURIComponent(key) + '=' + encodeURIComponent(payload[key]))
                .join('&'),
              params
            );

            if (response.status === 200) {
              const body = JSON.parse(response.body);
              tokens[user.username] = body.access_token;
              console.log(`Setup: Successfully fetched token for user: $${user.username}`);
            } else {
              console.error(`Setup: Failed to fetch token for user: $${user.username}, status: $${response.status}`);
            }
          });

          console.log(`Setup: Fetched $${Object.keys(tokens).length} tokens`);
          return { tokens: tokens };
        }

        // Function to generate a random delay between 2-5 seconds
        function getRandomDelay() {
          return Math.floor(Math.random() * 3000) + 2000; // 2-5 seconds in milliseconds
        }

        // Function to get random conversation length
        function getConversationLength() {
          return Math.floor(Math.random() * (MAX_MESSAGES - MIN_MESSAGES + 1)) + MIN_MESSAGES;
        }

        // Function to send a chat completion request
        function sendRequest(token, api, model, question) {
          const temperature = 0.7 + (Math.random() * 0.3);
          const max_tokens = 100 + Math.floor(Math.random() * 200);

          const request = {
            method: 'POST',
            url: TRAEFIK_URL,
            headers: {
              'Host': api.host,
              'Authorization': `Bearer $${token}`,
              'Content-Type': 'application/json',
              'X-Request-ID': randomString(16)
            },
            body: JSON.stringify({
              model: model,
              messages: [
                { "role": "user", "content": question }
              ],
              temperature: temperature,
              max_tokens: max_tokens
            }),
          };

          return http.request(request.method, request.url, request.body, { headers: request.headers });
        }

        export const options = {
          vus: 3,
          iterations: 20,
          duration: '30m',
          startTime: '0s',
          gracefulStop: '30s',
          discardResponseBodies: true
        };

        // Main test function - simulates multi-turn conversations
        export default function (data) {
          // Select a random user and their token
          const usernames = Object.keys(data.tokens);
          const username = randomItem(usernames);
          const token = data.tokens[username];
          
          // Select a random API and model for this conversation
          const api = randomItem(APIS);
          const model = randomItem(api.models);
          
          // Determine conversation length
          const conversationLength = getConversationLength();
          
          console.log(`VU $${__VU} - Starting conversation for user: $${username}, API: $${api.host}, Model: $${model}, Messages: $${conversationLength}`);
          
          // Start a conversation with multiple messages
          for (let i = 0; i < conversationLength; i++) {
            // Pick a random question
            const question = randomItem(ALL_QUESTIONS);
            
            // Send the request
            const response = sendRequest(token, api, model, question);
            
            // Log the response
            console.log(`VU $${__VU} - User: $${username} - Message $${i + 1}/$${conversationLength} - Status: $${response.status}`);
            
            // Wait between messages (except after the last one)
            if (i < conversationLength - 1) {
              const delay = getRandomDelay();
              sleep(delay / 1000);
            }
          }
          
          console.log(`VU $${__VU} - Conversation ended for user: $${username}`);
          
          // Wait before starting a new conversation
          sleep(1);
        }
  YAML
}

resource "kubectl_manifest" "aigateway_traffic_testrun" {
  yaml_body = <<-YAML
    apiVersion: k6.io/v1alpha1
    kind: TestRun
    metadata:
      name: aigateway-traffic
      labels:
        app: aigateway-load-test
        test-type: semantic-cache-demo
    spec:
      parallelism: 1
      separate: false
      quiet: "false"
      arguments: --tag testid=aigateway-traffic --env SCENARIO=aigateway-traffic
      initializer:
        metadata:
          labels:
            initializer: "k6"
      script:
        configMap:
          name: aigateway-traffic
          file: load.js
  YAML

  depends_on = [kubectl_manifest.aigateway_traffic_configmap]
}
