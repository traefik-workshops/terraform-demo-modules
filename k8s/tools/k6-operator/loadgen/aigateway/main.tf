locals {
  # Encode the APIs configuration as JSON to pass to the k6 script
  apis_json = jsonencode([for api in var.apis : {
    url    = api.url
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
            "France's capital city is what?",
            "Name the capital city of France.",
            "Identify France's capital.",
            "What's the name of France's capital city?",
            "Remind me of the capital of France.",
            "Which city is the capital of France?",
            "State the capital of France.",
            "What city is France's capital called?",
            "Do you know France's capital city?",
            "Please provide the capital of France.",
            "Tell me France's capital city.",
            "France: what is its capital?",
            "What capital does France have?",
            "Which city functions as France's capital?",
            "Could you share the capital of France?",
            "What's the French capital?"
          ],
          quantum: [
            "Explain quantum computing in simple terms.",
            "How would you describe quantum computing to a beginner?",
            "Can you break down quantum computing for me?",
            "I need a simple explanation of quantum computing.",
            "What's quantum computing all about?",
            "Give a layman's explanation of quantum computing.",
            "Summarize quantum computing plainly.",
            "Describe the basics of quantum computing.",
            "Explain qubits and superposition simply.",
            "What makes quantum computers different from classical ones?",
            "Explain entanglement at a high level.",
            "Why are qubits powerful?",
            "What problems suit quantum computing?",
            "Define quantum gates simply.",
            "Describe quantum algorithms briefly.",
            "What is superposition?",
            "What is entanglement?",
            "How does quantum speedup work?",
            "Provide a short intro to quantum computing.",
            "Explain quantum measurement simply."
          ],
          aiBenefits: [
            "What are the main benefits of artificial intelligence?",
            "How can artificial intelligence be beneficial?",
            "What advantages does AI offer?",
            "In what ways is artificial intelligence helpful?",
            "What are the pros of AI technology?",
            "List key benefits of using AI.",
            "Why do companies adopt AI?",
            "How does AI improve efficiency?",
            "What value does AI bring to businesses?",
            "Benefits of AI in healthcare?",
            "Benefits of AI in finance?",
            "How does AI help customer support?",
            "Does AI reduce costs?",
            "Can AI enhance decision-making?",
            "How does AI improve personalization?",
            "Explain productivity gains from AI.",
            "Name AI benefits for developers.",
            "How does AI help data analysis?",
            "Is AI useful for automation?",
            "Top reasons to use AI?"
          ],
          blockchain: [
            "How does blockchain technology work?",
            "Can you explain how blockchain functions?",
            "What's the working principle behind blockchain?",
            "How would you describe blockchain technology?",
            "Explain the mechanism of blockchain.",
            "Define blocks and chains in blockchain.",
            "What is a distributed ledger?",
            "How do miners validate transactions?",
            "Explain consensus mechanisms.",
            "What's proof of work?",
            "What's proof of stake?",
            "How are blocks linked together?",
            "What is a smart contract?",
            "Explain blockchain immutability.",
            "What makes blockchain secure?",
            "Public vs private blockchains?",
            "How are transactions recorded?",
            "Why is decentralization important?",
            "What are blockchain nodes?",
            "How do blockchain networks scale?"
          ],
          relativity: [
            "Explain the theory of relativity.",
            "What is Einstein's theory of relativity?",
            "Can you describe the concept of relativity?",
            "How would you explain the theory of relativity?",
            "What does the theory of relativity state?",
            "Difference between special and general relativity?",
            "Explain time dilation simply.",
            "What is length contraction?",
            "How does gravity curve spacetime?",
            "Explain E=mc^2 briefly.",
            "What is the speed of light postulate?",
            "Describe spacetime curvature.",
            "How do black holes relate to relativity?",
            "What is gravitational time dilation?",
            "How was relativity proven?",
            "Explain reference frames simply.",
            "What are relativistic effects?",
            "Describe general covariance.",
            "How does GPS use relativity?",
            "What is the equivalence principle?"
          ],
          programming: [
            "What are the best programming languages to learn in 2025?",
            "Which programming languages should I learn this year?",
            "What are the top programming languages right now?",
            "Can you recommend programming languages to learn in 2025?",
            "What coding languages are most in demand currently?",
            "Which languages are best for web development?",
            "What should beginners learn first?",
            "What languages are best for data science?",
            "Best languages for systems programming?",
            "What about mobile app development languages?",
            "Languages for AI and ML?",
            "Which languages have strong ecosystems?",
            "What languages pay the most?",
            "Which languages are fastest growing?",
            "Languages suited for scripting tasks?",
            "What languages are great for cloud?",
            "Languages with easy learning curve?",
            "Which languages are most versatile?",
            "What languages are popular for backend?",
            "Which languages are used for DevOps?"
          ],
          geography: [
            "Name the longest river in the world.",
            "Which is the highest mountain on Earth?",
            "What is the largest ocean?",
            "Which desert is the largest?",
            "What is the smallest country by area?",
            "Which country has the most population?",
            "Name the largest island.",
            "Which country has the longest coastline?",
            "What is the deepest ocean trench?",
            "Which continent is the largest?",
            "Name the capital of Japan.",
            "Which river runs through Cairo?",
            "What is the capital of Canada?",
            "Which country borders both France and Spain?",
            "What is the largest lake by area?",
            "Which sea borders Italy to the east?",
            "What is the capital of Australia?",
            "Which country has the most time zones?",
            "Name a landlocked country in Africa.",
            "Which is the driest place on Earth?"
          ],
          history: [
            "When did World War II end?",
            "Who was the first President of the United States?",
            "What year did the Berlin Wall fall?",
            "Who discovered penicillin?",
            "When was the Magna Carta signed?",
            "Who was Cleopatra?",
            "What sparked World War I?",
            "Who was known as the Iron Lady?",
            "What empire built the Colosseum?",
            "When did the Renaissance begin?",
            "Who was Genghis Khan?",
            "When did the Roman Empire fall?",
            "What was the Industrial Revolution?",
            "Who was Nelson Mandela?",
            "When was the Declaration of Independence signed?",
            "Who invented the printing press?",
            "What was the Cold War?",
            "Who was Marie Curie?",
            "When did humans land on the Moon?",
            "Who was the first emperor of China?"
          ],
          science: [
            "What is photosynthesis?",
            "Define Newton's second law.",
            "What is the periodic table?",
            "Explain the water cycle briefly.",
            "What are the states of matter?",
            "Define an atom.",
            "What is DNA?",
            "Explain evolution briefly.",
            "What is plate tectonics?",
            "Define electricity in simple terms.",
            "What is a chemical reaction?",
            "Explain gravity simply.",
            "What is the speed of light?",
            "Define energy conservation.",
            "What is a cell?",
            "Explain the greenhouse effect.",
            "What are viruses?",
            "Define ecosystem.",
            "What is a galaxy?",
            "Explain mitosis simply."
          ],
          sports: [
            "Who won the last FIFA World Cup?",
            "How many players are on a soccer team?",
            "What is a touchdown in American football?",
            "How many points is a three-pointer in basketball?",
            "What is a grand slam in tennis?",
            "What does RBI stand for in baseball?",
            "How long is a marathon?",
            "What is offside in soccer?",
            "How many holes are in a standard golf course?",
            "What is a hat-trick?",
            "How many sets to win a tennis match?",
            "What is a penalty kick?",
            "How many periods in ice hockey?",
            "What is a strike in bowling?",
            "How many players in a volleyball team?",
            "What is a yellow card in soccer?",
            "What is a home run?",
            "How many Olympic rings are there?",
            "What is a free throw?",
            "Define a knockout in boxing."
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
          console.log(`    API URL: $${api.url}`);
          console.log(`    Model: $${model}`);
          console.log(`    Question: "$${question.substring(0, 50)}..."`);
          console.log(`    Temperature: $${temperature.toFixed(2)}`);
          console.log(`    Max tokens: $${max_tokens}`);
          console.log(`    Request ID: $${requestId}`);
          console.log(`    Authorization: Bearer $${token.substring(0, 20)}... (truncated for display)`);

          const request = {
            method: 'POST',
            url: api.url,
            headers: {
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

          console.log(`    Sending POST to: $${request.url}`);
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
          console.log(`VU $${__VU}: Selected API: $${api.url}`);
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
          console.log(`│ API: $${api.url}`);
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
