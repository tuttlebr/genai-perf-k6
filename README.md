# NVIDIA NIM for LLMs

## Environment Variables

```sh
INPUT_TOKENS_MEAN=256
INPUT_TOKENS_STDDEV=0
OUTPUT_TOKENS_MEAN=256
OUTPUT_TOKENS_STDDEV=0
NUM_PROMPTS=100
CONCURRENCY=128
RANDOM_SEED=42
MEASUREMENT_INTERVAL=500000
STABILITY_PERCENTAGE=95
PROFILE_EXPORT_FILE="/artifacts/profile_export.json"
TOKENIZER="meta-llama/Meta-Llama-3.1-8B-Instruct"
MODEL="meta/llama-3.2-11b-vision-instruct"
HF_TOKEN="hf_...." # Required if the tokenizer is gated.
URL="192.168.1.234:32070"
K6_PROMETHEUS_RW_SERVER_URL="http://192.168.1.234:30500/api/v1/write" # Location of destination prometheus URL
K6_MAX_TEST_TIME_MINS="10m"
```

## Kubernetes Initialization

[NVIDIA Cloud Native Stack](https://docs.nvidia.com/ai-enterprise/deployment-guide-cloud-native-service-add-on-pack/0.1.0/cns-setup.html)

## Helm Deployment

### Custom Values

`nim-custom-values.yaml`

```yaml
image:
  repository: "nvcr.io/nim/meta/llama3-8b-instruct"
  tag: "1.0.0"

model:
  ngcAPISecret: ngc-api

replicaCount: 1

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: nvidia.com/gpu.product
              operator: In
              values:
                - NVIDIA-L40S-SHARED

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 2
  metrics:
    - type: Pods
      pods:
        metric:
          name: num_requests_waiting_pct
        target:
          type: AverageValue
          averageValue: 0.05

prometheus-adapter:
  prometheus:
    url: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local
    port: 9090
  rules:
    custom:
      - seriesQuery: "num_requests_waiting"
        resources:
          overrides:
            service: { resource: "services" }
            namespace: { resource: "namespace" }
        name:
          matches: "num_requests_waiting"
          as: "num_requests_waiting_pct"
        metricsQuery: "num_requests_waiting / (num_requests_waiting + num_requests_running)"

resources:
  limits:
    nvidia.com/gpu: 1
  requests:
    nvidia.com/gpu: 1

persistence:
  enabled: true
  size: 30Gi
  existingClaim: "model-store-dev-inference-ms-0"

imagePullSecrets:
  - name: registry-secret

ingress:
  enabled: true

metrics:
  enabled: true
  serviceMonitor:
    enabled: true

service:
  type: LoadBalancer
```

### Boostrap

```sh
export NAMESPACE=nemo-inference-ms
export NGC_CLI_API_KEY=<updatye with your key...>
kubectl create namespace ${NAMESPACE}

kubectl --namespace ${NAMESPACE} create secret docker-registry registry-secret \
    --docker-server=nvcr.io \
    --docker-username='$oauthtoken' \
    --docker-password=${NGC_CLI_API_KEY}

kubectl --namespace ${NAMESPACE} create secret generic ngc-api \
    --from-literal=NGC_CLI_API_KEY=${NGC_CLI_API_KEY}

helm upgrade --install dev-inference-ms nim-llm \
    --namespace ${NAMESPACE} \
    --values nim-custom-values.yaml
```

## NVIDIA GenAI-Perf - Performance Testing

This will run performance tests for the model and generate synthetic request data.
`docker compose run triton-genai-perf`

```sh
=================================
== Triton Inference Server SDK ==
=================================

NVIDIA Release 24.04 (build 90085241)

Copyright (c) 2018-2023, NVIDIA CORPORATION & AFFILIATES.  All rights reserved.

Various files include modifications (c) NVIDIA CORPORATION & AFFILIATES.  All rights reserved.

This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.nvidia.com/ngc/nvidia-deep-learning-container-license

WARNING: The NVIDIA Driver was not detected.  GPU functionality will not be available.
   Use the NVIDIA Container Toolkit to start this container with GPU support; see
   https://docs.nvidia.com/datacenter/cloud-native/ .

tokenizer_config.json: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 700/700 [00:00<00:00, 4.96MB/s]
tokenizer.model: 100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 500k/500k [00:00<00:00, 3.10MB/s]
tokenizer.json: 100%|███████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 1.84M/1.84M [00:00<00:00, 7.92MB/s]
special_tokens_map.json: 100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 411/411 [00:00<00:00, 1.11MB/s]
genai-perf - INFO - Detected passthrough args: ['--max-threads=16']
genai-perf - INFO - Running Perf Analyzer : 'perf_analyzer -m meta/llama3-8b-instruct --async --input-data llm_inputs.json --endpoint v1/chat/completions --service-kind openai -u 192.168.1.234:32700 --measurement-interval 10000 --stability-percentage 95.0 --profile-export-file profile_export.json --concurrency-range 16  -i http --max-threads=16'
                                                      LLM Metrics
┏━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃            Statistic ┃           avg ┃           min ┃           max ┃           p99 ┃           p90 ┃           p75 ┃
┡━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ Request latency (ns) │ 6,640,549,178 │ 1,271,303,727 │ 9,491,956,068 │ 9,486,069,487 │ 9,484,279,714 │ 7,890,290,061 │
│     Num output token │           400 │            35 │           585 │           577 │           575 │           486 │
│      Num input token │         1,037 │           973 │         1,123 │         1,123 │         1,123 │         1,082 │
└──────────────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┴───────────────┘
Output token throughput (per sec): 922.59
Request throughput (per sec): 2.30
Generating 'Time to First Token' html
Generating 'Time to First Token' jpeg
Generating 'Request Latency' html
Generating 'Request Latency' jpeg
Generating 'Distribution of Input Tokens to Generated Tokens' html
Generating 'Distribution of Input Tokens to Generated Tokens' jpeg
Generating 'Time to First Token vs Number of Input Tokens' html
Generating 'Time to First Token vs Number of Input Tokens' jpeg
Generating 'Token-to-Token Latency vs Output Token Position' html
Generating 'Token-to-Token Latency vs Output Token Position' jpeg
```

## Grafana K6 - Load Testing

`docker compose run k6`

```sh

          /\      |‾‾| /‾‾/   /‾‾/
     /\  /  \     |  |/  /   /  /
    /  \/    \    |     (   /   ‾‾\
   /          \   |  |\  \ |  (‾)  |
  / __________ \  |__| \__\ \_____/ .io

     execution: local
        script: script.js
        output: -

     scenarios: (100.00%) 1 scenario, 32 max VUs, 10m30s max duration (incl. graceful stop):
              * use_all_the_data: 1000 iterations shared among 32 VUs (maxDuration: 10m0s, exec: nim, gracefulStop: 30s)


     data_received..................: 2.3 MB 9.2 kB/s
     data_sent......................: 9.0 MB 37 kB/s
     http_req_blocked...............: avg=24.79µs  min=3.84µs   med=9.49µs   max=1.36ms   p(90)=16.62µs  p(95)=19.97µs
     http_req_connecting............: avg=14.04µs  min=0s       med=0s       max=1.32ms   p(90)=0s       p(95)=0s
     http_req_duration..............: avg=3.85s    min=591.13µs med=241.81ms max=14.83s   p(90)=9.51s    p(95)=10.74s
       { expected_response:true }...: avg=3.85s    min=591.13µs med=241.81ms max=14.83s   p(90)=9.51s    p(95)=10.74s
     http_req_failed................: 0.00%  ✓ 0        ✗ 2000
     http_req_receiving.............: avg=90.65µs  min=23.88µs  med=84.71µs  max=7.66ms   p(90)=118.94µs p(95)=130.25µs
     http_req_sending...............: avg=231.22µs min=8.73µs   med=249.08µs max=742.13µs p(90)=314.36µs p(95)=335.8µs
     http_req_tls_handshaking.......: avg=0s       min=0s       med=0s       max=0s       p(90)=0s       p(95)=0s
     http_req_waiting...............: avg=3.85s    min=270.42µs med=241.55ms max=14.83s   p(90)=9.51s    p(95)=10.74s
     http_reqs......................: 2000   8.164373/s
     iteration_duration.............: avg=7.7s     min=355.62ms med=7.76s    max=14.83s   p(90)=10.75s   p(95)=11.6s
     iterations.....................: 1000   4.082187/s
     vus............................: 1      min=1      max=32
     vus_max........................: 32     min=32     max=32


running (04m05.0s), 00/32 VUs, 1000 complete and 0 interrupted iterations
use_all_the_data ✓ [======================================] 32 VUs  04m05.0s/10m0s  1000/1000 shared iters
```
