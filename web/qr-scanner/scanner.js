document.addEventListener('DOMContentLoaded', () => {
    const video = document.getElementById('video');
    const startButton = document.getElementById('startButton');
    const stopButton = document.getElementById('stopButton');
    const resultDiv = document.getElementById('result');
    let stream = null;
    let scanning = false;

    // Function to start the camera
    async function startCamera() {
        try {
            stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment' }
            });
            video.srcObject = stream;
            await video.play();
            startButton.disabled = true;
            stopButton.disabled = false;
            scanning = true;
            scanQRCode();
        } catch (err) {
            console.error('Error accessing camera:', err);
            resultDiv.textContent = 'Error accessing camera. Please make sure you have granted camera permissions.';
        }
    }

    // Function to stop the camera
    function stopCamera() {
        if (stream) {
            stream.getTracks().forEach(track => track.stop());
            video.srcObject = null;
            startButton.disabled = false;
            stopButton.disabled = true;
            scanning = false;
            resultDiv.textContent = 'Camera stopped';
        }
    }

    // Function to scan for QR codes
    function scanQRCode() {
        if (!scanning) return;

        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        context.drawImage(video, 0, 0, canvas.width, canvas.height);
        
        const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
        const code = jsQR(imageData.data, imageData.width, imageData.height);

        if (code) {
            resultDiv.textContent = `QR Code detected: ${code.data}`;
            // Optional: Add a small delay before continuing to scan
            setTimeout(() => {
                if (scanning) scanQRCode();
            }, 1000);
        } else {
            // Continue scanning if no QR code is detected
            requestAnimationFrame(scanQRCode);
        }
    }

    // Event listeners
    startButton.addEventListener('click', startCamera);
    stopButton.addEventListener('click', stopCamera);
}); 