# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN comfy node install --exit-on-fail comfyui-videohelpersuite@1.7.9 --mode remote || (echo "WARN: comfyui-videohelpersuite@1.7.9 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-videohelpersuite --mode remote)
RUN comfy node install --exit-on-fail seedvr2_videoupscaler@2.5.22 || (echo "WARN: seedvr2_videoupscaler@2.5.22 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail seedvr2_videoupscaler)

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors' --relative-path models/Unknown --filename 'ema_vae_fp16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_3b_fp8_e4m3fn.safetensors' --relative-path models/Unknown --filename 'seedvr2_ema_3b_fp8_e4m3fn.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="60 300 900 1800 3600" && for i in 1 2 3 4 5; do \
    rm -f /comfyui/models/SEEDVR2/seedvr2_ema_3b_fp8_e4m3fn.safetensors; \
    comfy model download --url 'https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/seedvr2_ema_3b_fp8_e4m3fn.safetensors' --relative-path models/SEEDVR2 --filename 'seedvr2_ema_3b_fp8_e4m3fn.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; \
    sleep $SLEEP; \
done && test $(stat -c%s /comfyui/models/SEEDVR2/seedvr2_ema_3b_fp8_e4m3fn.safetensors) -gt 3000000000 || (echo "ERROR: seedvr2 DiT podejrzanie mały" >&2; exit 1)

RUN BACKOFFS="60 300 900 1800 3600" && for i in 1 2 3 4 5; do \
    rm -f /comfyui/models/SEEDVR2/ema_vae_fp16.safetensors; \
    comfy model download --url 'https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors' --relative-path models/SEEDVR2 --filename 'ema_vae_fp16.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; \
    sleep $SLEEP; \
done && test $(stat -c%s /comfyui/models/SEEDVR2/ema_vae_fp16.safetensors) -gt 400000000 || (echo "ERROR: ema_vae podejrzanie mały" >&2; exit 1)
