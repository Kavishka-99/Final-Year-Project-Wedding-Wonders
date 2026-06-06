(async () => {
  try {
    const urls = [
      'https://router.huggingface.co/models/runwayml/stable-diffusion-v1-5',
      'https://router.huggingface.co/v1/models/runwayml/stable-diffusion-v1-5',
      'https://router.huggingface.co/v1/generate',
    ];
    for (const u of urls) {
      try {
        const res = await fetch(u, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${process.env.HF_API_KEY}`,
            'Content-Type': 'application/json',
            Accept: 'application/octet-stream',
          },
          body: JSON.stringify({ inputs: 'A wedding cake in a garden, photorealistic' }),
        });
        console.log('URL', u);
        console.log('  STATUS', res.status);
        console.log('  CONTENT-TYPE', res.headers.get('content-type'));
        const text = await res.text();
        console.log('  BODY-SNIPPET', text.slice(0, 600));
      } catch (innerErr) {
        console.error('  ERROR calling', u, innerErr);
      }
    }
  } catch (e) {
    console.error('ERROR', e);
  }
})();
