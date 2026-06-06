#!/usr/bin/env python3
"""
Generate image from text prompt using Hugging Face Inference Providers
Exits with code 0 on success, 1 on failure.
Outputs base64 image data to stdout on success.
"""
import sys
import os
import base64

def generate_image(api_key, prompt):
    try:
        from huggingface_hub import InferenceClient
    except ImportError:
        print("ERROR: huggingface_hub not installed. Install with: pip install huggingface_hub", file=sys.stderr)
        sys.exit(1)
    
    try:
        client = InferenceClient(api_key=api_key)
        image = client.text_to_image(
            model="runwayml/stable-diffusion-v1-5",
            prompt=prompt,
        )
        
        # Convert to base64
        b64 = base64.b64encode(image.content).decode('utf-8')
        print(b64)
        sys.exit(0)
    except Exception as e:
        print(f"ERROR: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("USAGE: python generate_image.py '<prompt>' [api_key]", file=sys.stderr)
        sys.exit(1)
    
    prompt = sys.argv[1]
    api_key = sys.argv[2] if len(sys.argv) > 2 else os.getenv("HF_API_KEY")
    
    if not api_key:
        print("ERROR: HF_API_KEY not provided or set", file=sys.stderr)
        sys.exit(1)
    
    generate_image(api_key, prompt)
