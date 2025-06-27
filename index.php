<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>FoLaToXR - Warp Edition</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js"></script>
  <link
    rel="stylesheet"
    href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css"
  />
  <link
    href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"
    rel="stylesheet"
  />
  <style>
    body {
      font-family: 'Inter', sans-serif;
      overflow: hidden;
      background-color: #111;
      position: relative;
      cursor: default;
    }
    
    /* Warp effect styles */
    #warpCanvas {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: 20;
      opacity: 0;
      pointer-events: none;
      transition: opacity 1s ease;
    }
    
    #warpCanvas.active {
      opacity: 1;
      pointer-events: auto;
    }
    
    .warp-text {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: white;
      font-family: 'Inter', sans-serif;
      font-size: 3rem;
      text-align: center;
      z-index: 30;
      opacity: 0;
      text-transform: uppercase;
      letter-spacing: -0.03em;
      filter: blur(8px);
      transition: all 1.2s cubic-bezier(0.16, 1, 0.3, 1);
      text-shadow: 0 0 10px rgba(209, 255, 255, 0.7);
      user-select: none;
      pointer-events: none;
    }
    
    .warp-text.active {
      opacity: 1;
      filter: blur(0);
    }

    /* Button styles */
    .button-container {
      display: flex;
      justify-content: center;
      align-items: center;
      height: 80px;
      margin-bottom: 24px;
      position: relative;
      width: 100%;
      max-width: 320px;
    }
    
    .button-wrapper {
      position: relative;
      display: flex;
      justify-content: center;
      align-items: center;
      width: 100%;
      transition: all 0.3s ease;
    }

    .button-wrapper:hover,
    .button-wrapper:focus-within {
      transform: scale(1.05);
      z-index: 10;
    }

    .button {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 100%;
      transition: transform 0.2s ease;
      cursor: pointer;
      position: relative;
      z-index: 5;
      border-radius: 8px;
      padding: 16px 32px;
      font-weight: 600;
      font-size: 1.1rem;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      user-select: none;
      text-decoration: none;
      outline-offset: 2px;
      transition: transform 0.3s ease; /* Transisi halus untuk transform */
    }
    
    .button:focus-visible {
      outline: 3px solid #2563eb; /* Tailwind blue-600 */
      outline-offset: 2px;
    }
    
    .button:hover {
      transform: scale(1.03);
    }

    /* Spinner animation */
    @keyframes spin {
      to {
        transform: rotate(360deg);
      }
    }
    
    /* Centering for main content */
    .main-content {
      display: flex;
      flex-direction: column;
      align-items: center;
      width: 100%;
    }
    
    .warp-indicator {
      position: fixed;
      top: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0, 123, 255, 0.2);
      color: white;
      padding: 10px 20px;
      border-radius: 30px;
      font-size: 0.9rem;
      z-index: 40;
      opacity: 0;
      transition: opacity 0.3s ease;
      backdrop-filter: blur(5px);
      border: 1px solid rgba(0, 123, 255, 0.3);
      user-select: none;
    }
    
    .warp-indicator.show {
      opacity: 1;
    }

    /* Responsive adjustments */
    @media (max-width: 400px) {
      .button-container {
        max-width: 100%;
        height: auto;
        margin-bottom: 16px;
      }
      .button {
        font-size: 1rem;
        padding: 14px 24px;
      }
      .warp-text {
        font-size: 2rem;
        padding: 0 10px;
      }
    }
  </style>
</head>
<body class="bg-gray-50 min-h-screen flex flex-col relative">
  <!-- Warp Effect Canvas -->
  <canvas id="warpCanvas" aria-label="Warp speed starfield animation"></canvas>
  <div id="warpText" class="warp-text" aria-live="polite" aria-atomic="true">WARP SPEED ENGAGED</div>
  
  <!-- Warp Indicator -->
  <div id="warpIndicator" class="warp-indicator" role="alert" aria-live="assertive" aria-atomic="true">
    <i class="fas fa-rocket mr-2" aria-hidden="true"></i>
    Warp sequence activated
  </div>
  
  <!-- Loading Overlay -->
  <div id="loadingOverlay" class="fixed inset-0 bg-white bg-opacity-80 flex items-center justify-center z-50" role="status" aria-live="polite" aria-label="Loading content">
    <svg class="animate-spin h-12 w-12 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden="true">
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path>
    </svg>
  </div>

  <header class="bg-white border-b border-gray-200">
    <div class="max-w-7xl mx-auto px-4 py-5 flex items-center justify-center">
      <h1 class="text-2xl font-bold text-blue-600 select-none">FoLaToXR</h1>
    </div>
  </header>

  <main class="flex-grow flex items-center justify-center px-4 py-10">
    <div class="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
      <h2 class="text-3xl font-semibold text-center mb-8 text-gray-800">Welcome</h2>
      <div class="main-content">
        <!-- Login Button Container -->
        <div class="button-container">
          <div class="button-wrapper">
            <button
              id="loginButton"
              type="button"
              class="button border border-blue-600 text-blue-600 hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-blue-600 focus:ring-offset-1 rounded-md"
              aria-label="Login to FoLaToXR"
            >
              <i class="fas fa-sign-in-alt text-xl mr-2" aria-hidden="true"></i>
              <span class="text-lg">Login</span>
            </button>
          </div>
        </div>
        
        <!-- Register Button Container -->
        <div class="button-container">
          <div class="button-wrapper">
            <button
              id="registerButton"
              type="button"
              class="button bg-blue-600 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-700 focus:ring-offset-1 rounded-md"
              aria-label="Register a new account on FoLaToXR"
            >
              <i class="fas fa-user-plus text-xl mr-2" aria-hidden="true"></i>
              <span class="text-lg">Register</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </main>

  <footer class="bg-white border-t border-gray-200">
    <div class="max-w-7xl mx-auto py-4 px-4 flex flex-col sm:flex-row items-center justify-between">
      <p class="text-gray-500 text-sm font-medium">© 2024 FoLaToXR. All rights reserved.</p>
      <div class="flex space-x-6 mt-3 sm:mt-0">
        <a href="#" aria-label="Instagram" class="text-gray-400 hover:text-pink-500 transition">
          <i class="fab fa-instagram"></i>
        </a>
      </div>
    </div>
  </footer>

 <script>
  // ============= WARP EFFECT STARFIELD =============
  const warpCanvas = document.getElementById('warpCanvas');
  const warpCtx = warpCanvas.getContext('2d');
  const warpText = document.getElementById('warpText');
  const warpIndicator = document.getElementById('warpIndicator');

  function resizeCanvas() {
    warpCanvas.width = window.innerWidth;
    warpCanvas.height = window.innerHeight;
  }

  resizeCanvas();
  window.addEventListener('resize', resizeCanvas);

  const numStars = 1900;
  const focalLength = warpCanvas.width * 2;
  let centerX = warpCanvas.width / 2;
  let centerY = warpCanvas.height / 2;
  const baseTrailLength = 2;
  const maxTrailLength = 30;
  
  let stars = [];
  let warpSpeed = 0;
  let animationActive = false;

  function initializeStars() {
    stars = Array.from({ length: numStars }, () => ({
      x: Math.random() * warpCanvas.width,
      y: Math.random() * warpCanvas.height,
      z: Math.random() * warpCanvas.width,
      o: 0.5 + Math.random() * 0.5,
      trail: []
    }));
  }

  function moveStars() {
    stars.forEach(star => {
      const speed = 1 + warpSpeed * 50;
      star.z -= speed;

      if (star.z < 1) {
        star.z = warpCanvas.width;
        star.x = Math.random() * warpCanvas.width;
        star.y = Math.random() * warpCanvas.height;
        star.trail = [];
      }
    });
  }

  function drawStars() {
    const clearAlpha = 1 - warpSpeed * 0.8;
    warpCtx.fillStyle = `rgba(17,17,17,${clearAlpha})`;
    warpCtx.fillRect(0, 0, warpCanvas.width, warpCanvas.height);
  
    const trailLength = Math.floor(baseTrailLength + warpSpeed * (maxTrailLength - baseTrailLength));
  
    stars.forEach(star => {
      const px = (star.x - centerX) * (focalLength / star.z) + centerX;
      const py = (star.y - centerY) * (focalLength / star.z) + centerY;
      
      star.trail.push({ x: px, y: py });
      if (star.trail.length > trailLength) {
        star.trail.shift();
      }
  
      if (star.trail.length > 1) {
        warpCtx.beginPath();
        warpCtx.moveTo(star.trail[0].x, star.trail[0].y);
        star.trail.forEach((point, j) => {
          if (j > 0) warpCtx.lineTo(point.x, point.y);
        });
        warpCtx.strokeStyle = `rgba(209,255,255,${star.o})`;
        warpCtx.lineWidth = 1;
        warpCtx.stroke();
      }
  
      warpCtx.fillStyle = `rgba(209,255,255,${star.o})`;
      warpCtx.fillRect(px, py, 1.5, 1.5);
    });
  }

  function animateWarp() {
    if (animationActive) {
      requestAnimationFrame(animateWarp);
      moveStars();
      drawStars();
    }
  }

  function startWarpEffect(action) {
    warpIndicator.textContent = action === 'login' 
      ? "Login warp sequence activated" 
      : "Registration warp sequence activated";
    warpIndicator.classList.add('show');
  
    warpCanvas.classList.add('active');
    warpText.textContent = action === 'login' 
      ? "LOGIN WARP ENGAGED" 
      : "REGISTRATION WARP ENGAGED";
    warpText.classList.add('active');
  
    initializeStars();
    animationActive = true;
    animateWarp();
  
    const warpTimeline = gsap.timeline({
      onComplete: () => {
        setTimeout(() => {
          warpCanvas.classList.remove('active');
          warpText.classList.remove('active');
          warpIndicator.classList.remove('show');
          warpSpeed = 0;
          animationActive = false;
        }, 500);
      }
    });
  
    warpTimeline
      .to({}, {
        duration: 1,
        onUpdate: function() {
          warpSpeed = this.progress() * 0.8;
        }
      })
      .to({}, {
        duration: 1.5,
        onUpdate: function() {
          warpSpeed = 0.8 + this.progress() * 0.2;
        }
      })
      .to(warpText, {
        opacity: 0,
        filter: 'blur(20px)',
        duration: 0.5
      }, '-=0.5');
  }

  let loginClickCount = 0;
  let registerClickCount = 0;
  const totalClicksBeforeWarp = 10;

  function moveButtonRandomly(button) {
    const container = document.querySelector('.main-content');
    const buttonRect = button.getBoundingClientRect();
    const containerRect = container.getBoundingClientRect();
  
    const maxX = containerRect.width - buttonRect.width;
    const maxY = containerRect.height - buttonRect.height;

    const randomX = (Math.random() - 0.5) * 300; 
    const randomY = (Math.random() - 0.5) * 300; 
  
    button.style.transform = `translate(${randomX}px, ${randomY}px)`;
  }

  function prepareWarpEffect(action) {
    const loginButton = document.getElementById('loginButton');
    const registerButton = document.getElementById('registerButton');
    
    loginButton.style.transform = `translate(0, 0)`;
    registerButton.style.transform = `translate(0, 0)`;
    
    startWarpEffect(action);
  }

  const handleClick = (action, button) => {
    loginClickCount += action === 'login' ? 1 : 0;
    registerClickCount += action === 'register' ? 1 : 0;

    moveButtonRandomly(button);

    if ((action === 'login' && loginClickCount >= totalClicksBeforeWarp) || (action === 'register' && registerClickCount >= totalClicksBeforeWarp)) {
      prepareWarpEffect(action);
      if (action === 'login') loginClickCount = 0;
      else registerClickCount = 0;
    }
  };

  window.addEventListener('load', () => {
    const loginButton = document.getElementById('loginButton');
    const registerButton = document.getElementById('registerButton');

    loginButton.addEventListener('click', (e) => {
      e.preventDefault();
      handleClick('login', loginButton);
    });

    registerButton.addEventListener('click', (e) => {
      e.preventDefault();
      handleClick('register', registerButton);
    });

    initializeStars();

    setTimeout(() => {
      const loadingOverlay = document.getElementById('loadingOverlay');
      if (loadingOverlay) {
        loadingOverlay.style.display = 'none';
      }
    }, 2000);
  });
</script>
</body>
</html>

