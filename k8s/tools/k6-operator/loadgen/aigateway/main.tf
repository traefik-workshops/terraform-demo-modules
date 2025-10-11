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
          console.log('=== SETUP PHASE START ===');
          console.log(`Setup: Configuration loaded - APIS: $${APIS.length}, USERS: $${USERS.length}`);
          console.log(`Setup: Keycloak URL: $${KEYCLOAK_URL}`);
          console.log(`Setup: Client ID: $${CLIENT_ID}`);
          console.log(`Setup: Fetching JWT tokens for all users...`);
          
          const tokens = {};
          let successCount = 0;
          let failureCount = 0;
          
          USERS.forEach((user, index) => {
            console.log(`\n--- Processing user $${index + 1}/$${USERS.length}: $${user.username} ---`);
            
            const payload = {
              client_id: CLIENT_ID,
              grant_type: 'password',
              client_secret: CLIENT_SECRET,
              scope: 'openid',
              username: user.username,
              password: user.password
            };

            console.log(`Setup: Payload prepared for $${user.username}`);
            console.log(`Setup: Username: $${user.username}`);
            console.log(`Setup: Grant type: $${payload.grant_type}`);
            console.log(`Setup: Scope: $${payload.scope}`);

            const params = {
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
            };

            const formBody = Object.keys(payload)
              .map(key => encodeURIComponent(key) + '=' + encodeURIComponent(payload[key]))
              .join('&');
            
            console.log(`Setup: Sending POST request to Keycloak for $${user.username}...`);
            
            const response = http.post(
              KEYCLOAK_URL,
              formBody,
              params
            );

            console.log(`Setup: Response received for $${user.username}`);
            console.log(`Setup: Status code: $${response.status}`);
            console.log(`Setup: Response body length: $${response.body ? response.body.length : 0} bytes`);

            if (response.status === 200) {
              try {
                const body = JSON.parse(response.body);
                console.log(`Setup: Response parsed successfully for $${user.username}`);
                
                if (body.access_token) {
                  tokens[user.username] = body.access_token;
                  const tokenPreview = body.access_token.substring(0, 20) + '...';
                  console.log(`Setup: ✓ Token acquired for $${user.username} (preview: $${tokenPreview})`);
                  console.log(`Setup: Token type: $${body.token_type || 'N/A'}`);
                  console.log(`Setup: Expires in: $${body.expires_in || 'N/A'} seconds`);
                  successCount++;
                } else {
                  console.error(`Setup: ✗ No access_token in response for $${user.username}`);
                  console.error(`Setup: Response keys: $${Object.keys(body).join(', ')}`);
                  console.error(`Setup: Full response body: $${response.body}`);
                  failureCount++;
                }
              } catch (e) {
                console.error(`Setup: ✗ Failed to parse JSON response for $${user.username}`);
                console.error(`Setup: Parse error: $${e.message}`);
                console.error(`Setup: Response body: $${response.body}`);
                failureCount++;
              }
            } else {
              console.error(`Setup: ✗ HTTP error for $${user.username}`);
              console.error(`Setup: Status: $${response.status}`);
              console.error(`Setup: Status text: $${response.status_text || 'N/A'}`);
              console.error(`Setup: Response body: $${response.body}`);
              failureCount++;
            }
          });

          console.log(`\n=== SETUP PHASE COMPLETE ===`);
          console.log(`Setup: Total users processed: $${USERS.length}`);
          console.log(`Setup: Successful token fetches: $${successCount}`);
          console.log(`Setup: Failed token fetches: $${failureCount}`);
          console.log(`Setup: Tokens stored: $${Object.keys(tokens).length}`);
          console.log(`Setup: User list with tokens: $${Object.keys(tokens).join(', ')}`);
          
          if (Object.keys(tokens).length === 0) {
            console.error('Setup: CRITICAL - No tokens were fetched! Test cannot proceed.');
            throw new Error('Setup failed: No authentication tokens available');
          }
          
          console.log('Setup: Returning token data to test execution...\n');
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
        function sendRequest(token, api, model, question, messageNum, totalMessages, username) {
          const temperature = 0.7 + (Math.random() * 0.3);
          const max_tokens = 100 + Math.floor(Math.random() * 200);
          const requestId = randomString(16);

          console.log(`  → Request $${messageNum}/$${totalMessages}: Preparing chat completion`);
          console.log(`    User: $${username}`);
          console.log(`    API Host: $${api.host}`);
          console.log(`    Model: $${model}`);
          console.log(`    Question: "$${question.substring(0, 50)}..."`);
          console.log(`    Temperature: $${temperature.toFixed(2)}`);
          console.log(`    Max tokens: $${max_tokens}`);
          console.log(`    Request ID: $${requestId}`);
          console.log(`    Authorization: Bearer $${token.substring(0, 20)}... (truncated for display)`);

          const request = {
            method: 'POST',
            url: TRAEFIK_URL,
            headers: {
              'Host': api.host,
              'Authorization': `Bearer $${token}`,
              'Content-Type': 'application/json',
              'X-Request-ID': requestId
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

          console.log(`    Sending POST to: $${TRAEFIK_URL}`);
          const startTime = new Date().getTime();
          
          const response = http.request(request.method, request.url, request.body, { headers: request.headers });
          
          const endTime = new Date().getTime();
          const duration = endTime - startTime;
          
          console.log(`  ← Response $${messageNum}/$${totalMessages}: Received`);
          console.log(`    Status: $${response.status}`);
          console.log(`    Duration: $${duration}ms`);
          console.log(`    Body length: $${response.body ? response.body.length : 0} bytes`);
          
          if (response.status !== 200) {
            console.error(`    ERROR: Non-200 status code`);
            console.error(`    Response body: $${response.body ? response.body.substring(0, 200) : 'empty'}`);
          } else {
            console.log(`    ✓ Success`);
            try {
              const responseBody = JSON.parse(response.body);
              if (responseBody.choices && responseBody.choices.length > 0) {
                const content = responseBody.choices[0].message.content;
                console.log(`    Response preview: "$${content.substring(0, 60)}..."`);
              }
            } catch (e) {
              console.log(`    Could not parse response body for preview`);
            }
          }
          
          return response;
        }

        export const options = {
          vus: 3,
          iterations: 20,
          duration: '30m',
          // Note: discardResponseBodies is NOT set here because we need response bodies
          // in the setup phase to extract JWT tokens. For the main test, we can
          // selectively discard bodies if needed for performance.
        };

        // Main test function - simulates multi-turn conversations
        export default function (data) {
          console.log(`\n╔═══════════════════════════════════════════════════════════════╗`);
          console.log(`║ VU $${__VU} - ITERATION $${__ITER} START`);
          console.log(`╚═══════════════════════════════════════════════════════════════╝`);
          
          // Validate data
          if (!data || !data.tokens) {
            console.error(`VU $${__VU}: CRITICAL ERROR - No token data received from setup!`);
            console.error(`VU $${__VU}: Data object: $${JSON.stringify(data)}`);
            throw new Error('No token data available');
          }
          
          // Select a random user and their token
          const usernames = Object.keys(data.tokens);
          console.log(`VU $${__VU}: Available users: $${usernames.join(', ')}`);
          console.log(`VU $${__VU}: Total users available: $${usernames.length}`);
          
          if (usernames.length === 0) {
            console.error(`VU $${__VU}: CRITICAL ERROR - No users with tokens available!`);
            throw new Error('No authenticated users available');
          }
          
          const username = randomItem(usernames);
          const token = data.tokens[username];
          
          console.log(`VU $${__VU}: Selected user: $${username}`);
          console.log(`VU $${__VU}: Token preview: $${token.substring(0, 20)}...`);
          
          // Select a random API and model for this conversation
          console.log(`VU $${__VU}: Available APIs: $${APIS.length}`);
          const api = randomItem(APIS);
          console.log(`VU $${__VU}: Selected API: $${api.host}`);
          console.log(`VU $${__VU}: Available models for this API: $${api.models.join(', ')}`);
          
          const model = randomItem(api.models);
          console.log(`VU $${__VU}: Selected model: $${model}`);
          
          // Determine conversation length
          const conversationLength = getConversationLength();
          console.log(`VU $${__VU}: Conversation length: $${conversationLength} messages`);
          console.log(`VU $${__VU}: Question pool size: $${ALL_QUESTIONS.length} questions`);
          
          console.log(`\n┌─────────────────────────────────────────────────────────────┐`);
          console.log(`│ VU $${__VU}: Starting conversation`);
          console.log(`│ User: $${username}`);
          console.log(`│ API: $${api.host}`);
          console.log(`│ Model: $${model}`);
          console.log(`│ Messages: $${conversationLength}`);
          console.log(`└─────────────────────────────────────────────────────────────┘\n`);
          
          let successfulRequests = 0;
          let failedRequests = 0;
          
          // Start a conversation with multiple messages
          for (let i = 0; i < conversationLength; i++) {
            console.log(`\n--- Message $${i + 1}/$${conversationLength} ---`);
            
            // Pick a random question
            const question = randomItem(ALL_QUESTIONS);
            console.log(`VU $${__VU}: Question selected: "$${question}"`);
            
            // Send the request
            const response = sendRequest(token, api, model, question, i + 1, conversationLength, username);
            
            // Track success/failure
            if (response.status === 200) {
              successfulRequests++;
            } else {
              failedRequests++;
            }
            
            // Wait between messages (except after the last one)
            if (i < conversationLength - 1) {
              const delay = getRandomDelay();
              console.log(`VU $${__VU}: Waiting $${delay}ms before next message...`);
              sleep(delay / 1000);
            }
          }
          
          console.log(`\n┌─────────────────────────────────────────────────────────────┐`);
          console.log(`│ VU $${__VU}: Conversation Summary`);
          console.log(`│ User: $${username}`);
          console.log(`│ Total messages: $${conversationLength}`);
          console.log(`│ Successful: $${successfulRequests}`);
          console.log(`│ Failed: $${failedRequests}`);
          console.log(`│ Success rate: $${((successfulRequests / conversationLength) * 100).toFixed(1)}%`);
          console.log(`└─────────────────────────────────────────────────────────────┘`);
          
          console.log(`\nVU $${__VU}: Waiting 1s before next iteration...`);
          sleep(1);
          
          console.log(`\n╔═══════════════════════════════════════════════════════════════╗`);
          console.log(`║ VU $${__VU} - ITERATION $${__ITER} COMPLETE`);
          console.log(`╚═══════════════════════════════════════════════════════════════╝\n`);
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
