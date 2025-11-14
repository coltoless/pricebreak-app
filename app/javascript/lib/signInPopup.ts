// Sign-in popup functionality
import { initializeFirebaseUI } from './firebaseui';

// Create a popup sign-in modal
export const showSignInPopup = () => {
  // Create modal overlay
  const overlay = document.createElement('div');
  overlay.id = 'sign-in-popup-overlay';
  overlay.style.cssText = `
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.75);
    backdrop-filter: blur(4px);
    z-index: 10000;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
  `;

  // Create modal container
  const container = document.createElement('div');
  container.id = 'sign-in-popup-container';
  container.style.cssText = `
    background: #1F2937;
    border-radius: 1rem;
    padding: 2rem;
    max-width: 420px;
    width: 100%;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
    position: relative;
    color: white;
  `;

  // Create header with padlock icon
  const header = document.createElement('div');
  header.style.cssText = `
    margin-bottom: 1.5rem;
  `;
  header.innerHTML = `
    <div style="display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.5rem;">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink: 0;">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
      </svg>
      <h2 style="color: white; font-size: 1.5rem; font-weight: 700; margin: 0;">
        Unlock the full experience
      </h2>
    </div>
    <p style="color: #D1D5DB; font-size: 0.875rem; margin: 0; line-height: 1.5;">
      Log in or create an account with PriceBreak to get started.
    </p>
  `;

  // Create close button
  const closeButton = document.createElement('button');
  closeButton.innerHTML = '×';
  closeButton.setAttribute('aria-label', 'Close');
  closeButton.style.cssText = `
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: rgba(255, 255, 255, 0.1);
    border: none;
    font-size: 1.5rem;
    color: white;
    cursor: pointer;
    width: 2rem;
    height: 2rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
    transition: all 0.2s;
    line-height: 1;
  `;
  closeButton.onmouseover = () => {
    closeButton.style.background = 'rgba(255, 255, 255, 0.2)';
  };
  closeButton.onmouseout = () => {
    closeButton.style.background = 'rgba(255, 255, 255, 0.1)';
  };
  closeButton.onclick = () => {
    if (overlay.parentNode) {
      document.body.removeChild(overlay);
    }
  };

  // Create FirebaseUI container
  const firebaseuiContainer = document.createElement('div');
  firebaseuiContainer.id = 'firebaseui-popup-container';
  firebaseuiContainer.style.cssText = `
    margin-bottom: 1.5rem;
  `;

  // Create footer with terms and privacy policy
  const footer = document.createElement('div');
  footer.style.cssText = `
    text-align: center;
    padding-top: 1rem;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    margin-top: 1rem;
  `;
  footer.innerHTML = `
    <p style="color: #9CA3AF; font-size: 0.75rem; margin: 0; line-height: 1.5;">
      By continuing you agree to PriceBreak's 
      <a href="/terms" style="color: #60A5FA; text-decoration: underline; cursor: pointer;">Terms of Service</a> 
      and 
      <a href="/privacy" style="color: #60A5FA; text-decoration: underline; cursor: pointer;">Privacy Policy</a>.
    </p>
  `;

  // Assemble modal
  container.appendChild(closeButton);
  container.appendChild(header);
  container.appendChild(firebaseuiContainer);
  container.appendChild(footer);
  overlay.appendChild(container);

  // Close on overlay click
  overlay.onclick = (e) => {
    if (e.target === overlay) {
      document.body.removeChild(overlay);
    }
  };

  // Add to page
  document.body.appendChild(overlay);

  // Add custom styles for FirebaseUI in dark theme
  const style = document.createElement('style');
  style.textContent = `
    #firebaseui-popup-container .firebaseui-container {
      max-width: 100%;
      background: transparent;
    }
    #firebaseui-popup-container .firebaseui-card-content {
      padding: 0;
    }
    #firebaseui-popup-container .firebaseui-title,
    #firebaseui-popup-container .firebaseui-subtitle {
      display: none;
    }
    #firebaseui-popup-container .firebaseui-list-item {
      margin-bottom: 0.75rem;
    }
    #firebaseui-popup-container .firebaseui-button {
      background: #2563EB !important;
      border: none !important;
      border-radius: 0.5rem !important;
      padding: 0.75rem 1rem !important;
      font-size: 0.875rem !important;
      font-weight: 500 !important;
      color: white !important;
      width: 100% !important;
      transition: all 0.2s !important;
    }
    #firebaseui-popup-container .firebaseui-button:hover {
      background: #1D4ED8 !important;
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.4);
    }
    #firebaseui-popup-container .firebaseui-idp-google {
      background: white !important;
      color: #1F2937 !important;
    }
    #firebaseui-popup-container .firebaseui-idp-google:hover {
      background: #F9FAFB !important;
    }
    #firebaseui-popup-container .firebaseui-idp-icon-wrapper {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    #firebaseui-popup-container .firebaseui-idp-text {
      font-size: 0.875rem !important;
      font-weight: 500 !important;
    }
    #firebaseui-popup-container .firebaseui-form-actions {
      margin: 0;
    }
    #firebaseui-popup-container .firebaseui-input {
      background: rgba(255, 255, 255, 0.1) !important;
      border: 1px solid rgba(255, 255, 255, 0.2) !important;
      border-radius: 0.5rem !important;
      color: white !important;
      padding: 0.75rem !important;
    }
    #firebaseui-popup-container .firebaseui-input::placeholder {
      color: #9CA3AF !important;
    }
    #firebaseui-popup-container .firebaseui-label {
      color: #D1D5DB !important;
    }
    #firebaseui-popup-container .firebaseui-error {
      color: #FCA5A5 !important;
      background: rgba(239, 68, 68, 0.1) !important;
      border: 1px solid rgba(239, 68, 68, 0.3) !important;
      border-radius: 0.5rem !important;
      padding: 0.75rem !important;
    }
  `;
  document.head.appendChild(style);

  // Initialize FirebaseUI in the popup
  setTimeout(() => {
    initializeFirebaseUI('firebaseui-popup-container', {
      callbacks: {
        signInSuccessWithAuthResult: function(authResult: any, redirectUrl?: string) {
          // Close popup on successful sign-in
          if (overlay.parentNode) {
            document.body.removeChild(overlay);
          }
          
          // Get the ID token and send it to our Rails backend
          authResult.user.getIdToken().then((idToken: string) => {
            fetch('/api/auth/login', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
              }
            }).then(response => {
              if (response.ok) {
                console.log('✅ Backend authentication successful');
                // Reload page to update UI
                window.location.reload();
              } else {
                console.error('❌ Backend authentication failed');
              }
            }).catch(error => {
              console.error('❌ Backend authentication error:', error);
            });
          });

          return false; // Don't redirect automatically
        },
        uiShown: function() {
          // Hide loader if it exists
          const loader = document.getElementById('sign-in-popup-loader');
          if (loader) {
            loader.style.display = 'none';
          }
        }
      }
    });
  }, 100);
};

// Make it available globally
if (typeof window !== 'undefined') {
  (window as any).showSignInPopup = showSignInPopup;
}

