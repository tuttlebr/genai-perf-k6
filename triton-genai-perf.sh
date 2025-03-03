#!/bin/bash
set -e

invoke_url="${OPENAI_BASE_URL}/v1/chat/completions"

authorization_header="Authorization: Bearer ${NGC_API_KEY}"
accept_header="Accept: application/json"
content_type_header="Content-Type: application/json"

data=$'{
  "messages": [
    {
      "role": "user",
      "content": "What time is it?"
    }
  ],
  "stream": false,
  "model": "meta/llama-3.1-8b-instruct",
  "max_tokens": 1024,
  "presence_penalty": 0,
  "frequency_penalty": 0,
  "top_p": 0.7,
  "temperature": 0.2
}'

echo "Invoking ${invoke_url} with ${data}"
response=$(curl --silent -i -k -w "\n%{http_code}" --request POST \
  --url "$invoke_url" \
  --header "$authorization_header" \
  --header "$accept_header" \
  --header "$content_type_header" \
  --data "$data"
)

echo "$response"

genai-perf profile \
  -m ${MODEL} \
  --service-kind openai \
  --endpoint-type chat \
  --random-seed ${RANDOM_SEED} \
  --synthetic-input-tokens-mean ${INPUT_TOKENS_MEAN} \
  --synthetic-input-tokens-stddev ${INPUT_TOKENS_STDDEV} \
  --output-tokens-mean ${OUTPUT_TOKENS_MEAN} \
  --output-tokens-stddev ${OUTPUT_TOKENS_STDDEV} \
  --stability-percentage ${STABILITY_PERCENTAGE} \
  --measurement-interval ${MEASUREMENT_INTERVAL} \
  --num-prompts ${NUM_PROMPTS} \
  --tokenizer ${TOKENIZER} \
  --url ${URL} \
  --streaming \
  --concurrency ${CONCURRENCY} \
  --header "Authorization: Bearer ${NGC_API_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  -- --max-threads=$(nproc)

# # --extra-inputs ignore_eos:true
