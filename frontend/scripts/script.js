/**
 * Ocean Sentinels - Main JavaScript
 * Enhanced Login & Registration System
 * Version: 2.1 - Updated Sep 30, 2025
 * Features: Demo accounts + Real database authentication
 */

// Wait for the entire HTML document to be loaded before running the script
document.addEventListener('DOMContentLoaded', () => {

    // --- DEMO POPUP INITIALIZATION ---
    const demoPopup = document.getElementById('demo-popup');
    const demoCloseButton = document.querySelector('.demo-close-button');
    const demoCloseBtn = document.querySelector('.demo-close-btn');

    // Initialize demo popup on page load
    function initializeDemoPopup() {
        // Check if user is already logged in
        const authToken = localStorage.getItem('oceanGuardToken');
        const hasSeenDemoPopup = localStorage.getItem('hasSeenDemoPopup');
        
        // Only show popup if user is NOT logged in and hasn't seen it before
        if (!authToken && !hasSeenDemoPopup) {
            // Show demo popup only if not authenticated and first visit
            demoPopup.classList.remove('hidden');
            
            // Add close functionality to the close button (X)
            if (demoCloseButton) {
                demoCloseButton.addEventListener('click', closeDemoPopup);
            }
            
            // Add close functionality to the "Get Started" button
            if (demoCloseBtn) {
                demoCloseBtn.addEventListener('click', closeDemoPopup);
            }
            
            // Close popup when clicking outside the modal
            window.addEventListener('click', (event) => {
                if (event.target === demoPopup) {
                    closeDemoPopup();
                }
            });
        } else {
            // Hide popup if user is logged in or has already seen it
            demoPopup.classList.add('hidden');
        }
    }

    function closeDemoPopup() {
        demoPopup.classList.add('hidden');
        // Remember that user has seen the popup
        localStorage.setItem('hasSeenDemoPopup', 'true');
    }

    // Initialize demo popup on page load
    initializeDemoPopup();

    // --- SECTION 1: ELEMENT SELECTION ---

    const authModal = document.getElementById('auth-modal');
    const reportModal = document.getElementById('report-modal');
    const loginButton = document.getElementById('login-btn');
    const citizenLoginButton = document.getElementById('citizen-login-btn');
    const reportButtons = document.querySelectorAll('#report-hazard-btn, #hero-report-btn');
    const closeButtons = document.querySelectorAll('.close-button');
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    const reportForm = document.getElementById('hazard-report-modal-form');
    const navActions = document.querySelector('.nav-actions');

    // Authentication modal elements
    const authTabs = document.querySelectorAll('.auth-tab');
    const authSections = document.querySelectorAll('.auth-section');
    const passwordToggles = document.querySelectorAll('.password-toggle i');

    // --- SECTION 2: UTILITY FUNCTIONS ---
    
    function generateReferenceId() {
        const timestamp = Date.now().toString(36);
        const randomStr = Math.random().toString(36).substring(2, 8).toUpperCase();
        return `OG-${timestamp}-${randomStr}`;
    }

    function getCurrentLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject('Geolocation is not supported by this browser');
                return;
            }
            
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const lat = position.coords.latitude.toFixed(6);
                    const lng = position.coords.longitude.toFixed(6);
                    resolve(`${lat}, ${lng}`);
                },
                (error) => {
                    reject('Unable to retrieve location');
                }
            );
        });
    }

    // --- SECTION 3: MODAL MANAGEMENT ---

    function openModal(modal) {
        if (modal) {
            // Use requestAnimationFrame for smoother modal opening
            requestAnimationFrame(() => {
                modal.classList.add('show');
                document.body.style.overflow = 'hidden';
            });
        }
    }

    function closeModal(modal) {
        if (modal) {
            console.log('Closing modal:', modal.id);
            modal.classList.remove('show');
            document.body.style.overflow = 'auto';
            
            // Re-enable any disabled submit buttons in the modal
            const submitBtns = modal.querySelectorAll('button[type="submit"]');
            submitBtns.forEach(btn => {
                if (btn.disabled) {
                    btn.disabled = false;
                    // Reset button text if it was changed
                    if (btn.innerHTML.includes('fa-spinner')) {
                        const reportBtn = modal.querySelector('.report-submit-btn');
                        if (reportBtn) {
                            reportBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Submit Report';
                        }
                    }
                }
            });
            console.log('Modal closed successfully');
        }
    }

    // --- SECTION 4: AUTHENTICATION MODAL FUNCTIONALITY ---

    // Tab switching
    authTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const tabName = tab.getAttribute('data-tab');
            
            // Update active tab
            authTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            
            // Show corresponding section
            authSections.forEach(section => {
                section.classList.remove('active');
                if (section.id === `${tabName}-section`) {
                    section.classList.add('active');
                }
            });
        });
    });

    // Password visibility toggle
    passwordToggles.forEach(toggle => {
        toggle.addEventListener('click', () => {
            const input = toggle.parentElement.previousElementSibling;
            const isPassword = input.type === 'password';
            
            input.type = isPassword ? 'text' : 'password';
            toggle.className = isPassword ? 'fas fa-eye-slash' : 'fas fa-eye';
        });
    });

    // --- SECTION 5: EVENT LISTENERS ---

    // Open authentication modal
    if (loginButton) {
        loginButton.addEventListener('click', (e) => {
            e.preventDefault();
            openModal(authModal);
        });
    }

    if (citizenLoginButton) {
        citizenLoginButton.addEventListener('click', (e) => {
            e.preventDefault();
            openModal(authModal);
        });
    }

    // Open report modal
    reportButtons.forEach(button => {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            openModal(reportModal);
        });
    });

    // Close modals
    closeButtons.forEach(button => {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            const modal = button.closest('.modal');
            console.log('Close button clicked, modal:', modal ? modal.id : 'none');
            if (modal) {
                closeModal(modal);
            }
        });
    });

    // Additional handler for report modal close button
    const closeReportBtn = document.getElementById('close-report-modal');
    if (closeReportBtn) {
        closeReportBtn.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('Report modal close button clicked');
            if (reportModal) {
                closeModal(reportModal);
            }
        });
    }

    // Close modal when clicking outside
    window.addEventListener('click', (event) => {
        if (event.target.classList.contains('modal')) {
            closeModal(event.target);
        }
    });

    // Get location button
    const getLocationBtn = document.getElementById('get-location');
    if (getLocationBtn) {
        getLocationBtn.addEventListener('click', async () => {
            const locationInput = document.getElementById('modal-location');
            getLocationBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Getting Location...';
            getLocationBtn.disabled = true;
            
            try {
                const coords = await getCurrentLocation();
                locationInput.value = coords;
                getLocationBtn.innerHTML = '<i class="fas fa-check"></i> Location Set';
                setTimeout(() => {
                    getLocationBtn.innerHTML = '<i class="fas fa-crosshairs"></i> Use My Location';
                    getLocationBtn.disabled = false;
                }, 2000);
            } catch (error) {
                alert('Could not get your location: ' + error);
                getLocationBtn.innerHTML = '<i class="fas fa-crosshairs"></i> Use My Location';
                getLocationBtn.disabled = false;
            }
        });
    }

    // --- SECTION 6: USER STATE & HEADER MANAGEMENT ---

    function checkLoginState() {
        // Check both localStorage and sessionStorage for user data
        const user = JSON.parse(localStorage.getItem('oceanGuardUser')) || 
                     JSON.parse(sessionStorage.getItem('oceanGuardUser'));

        if (user && user.role === 'public') {
            if (navActions) {
                navActions.innerHTML = `
                    <span class="welcome-user">Welcome, ${user.name}</span>
                    <a href="#" class="btn btn--primary" id="report-hazard-btn">New Report</a>
                    <a href="#" id="logout-button" class="btn btn--secondary">Logout</a>
                `;
                
                // Re-add event listeners
                const newReportBtn = document.getElementById('report-hazard-btn');
                const logoutBtn = document.getElementById('logout-button');
                
                if (newReportBtn) {
                    newReportBtn.addEventListener('click', (e) => {
                        e.preventDefault();
                        openModal(reportModal);
                    });
                }
                
                if (logoutBtn) {
                    logoutBtn.addEventListener('click', logout);
                }
            }
        } else if (user && user.role === 'admin') {
            if (navActions && (window.location.pathname.includes('index.html') || window.location.pathname === '/')) {
                navActions.innerHTML = `
                    <span class="welcome-user">Welcome, ${user.name}</span>
                    <a href="admin-dashboard.html" class="btn btn--primary">Admin Dashboard</a>
                    <a href="#" id="logout-button" class="btn btn--secondary">Logout</a>
                `;
                
                const logoutBtn = document.getElementById('logout-button');
                if (logoutBtn) {
                    logoutBtn.addEventListener('click', logout);
                }
            }
        } else if (user && (user.role === 'authority' || user.role === 'rescue_team')) {
            if (navActions) {
                navActions.innerHTML = `
                    <span class="welcome-user">Welcome, ${user.name || user.username}</span>
                    <a href="reports.html" class="btn btn--primary">Incident Reports</a>
                    <a href="#" id="logout-button" class="btn btn--secondary">Logout</a>
                `;
                
                const logoutBtn = document.getElementById('logout-button');
                if (logoutBtn) {
                    logoutBtn.addEventListener('click', logout);
                }
            }
        }
    }

    // --- SECTION 7: FORM HANDLING ---

    // Login form submission
    if (loginForm) {
        loginForm.addEventListener('submit', async (event) => {
            event.preventDefault();
            
            // Get form data from multiple sources to ensure we get the values
            const formData = new FormData(loginForm);
            const username = formData.get('username') || 
                           document.getElementById('login-username')?.value || '';
            const password = formData.get('password') || 
                           document.getElementById('login-password')?.value || '';
            
            console.log('🔐 Login attempt:', { username, hasPassword: !!password });
            
            // Check for demo/mock login first (case insensitive)
            const lowerUsername = username.toLowerCase().trim();
            
            if (lowerUsername === 'user' || lowerUsername === 'citizen') {
                const user = { 
                    name: 'Demo Citizen', 
                    role: 'public',
                    email: 'demo@citizen.com',
                    id: 999 
                };
                
                // Store in both storages for compatibility
                sessionStorage.setItem('oceanGuardUser', JSON.stringify(user));
                localStorage.setItem('oceanGuardUser', JSON.stringify(user));
                
                const mockToken = `mock-token-${user.role}-${Date.now()}`;
                localStorage.setItem('oceanGuardToken', mockToken);
                
                // Dispatch login event for navigation update
                window.dispatchEvent(new CustomEvent('userLoggedIn', { detail: user }));
                
                alert('Demo login successful! You can now view sample reports.');
                window.location.href = 'my-reports.html';
                return;
            } else if (lowerUsername === 'admin' || lowerUsername === 'rescue') {
                const user = { 
                    name: 'Demo Admin', 
                    role: 'admin',
                    email: 'admin@ocean.gov.in',
                    id: 1 
                };
                
                sessionStorage.setItem('oceanGuardUser', JSON.stringify(user));
                localStorage.setItem('oceanGuardUser', JSON.stringify(user));
                
                const mockToken = `mock-token-${user.role}-${Date.now()}`;
                localStorage.setItem('oceanGuardToken', mockToken);
                
                // Dispatch login event for navigation update
                window.dispatchEvent(new CustomEvent('userLoggedIn', { detail: user }));
                
                alert('Demo admin login successful!');
                window.location.href = 'admin-dashboard.html';
                return;
            }
            
            // Real API login for registered users
            if (!username || !password) {
                alert('Please enter both username and password for database users.\n\nQuick Demo Access (no password needed):\n• Username: "user" or "citizen" - Public access\n• Username: "admin" or "rescue" - Admin access\n\nOr use database accounts:\n• demo_citizen / citizen123\n• demo_admin / admin123');
                return;
            }
            
            try {
                const api = new OceanHazardAPI();
                console.log('🔐 Attempting real API login for:', username);
                
                const response = await api.login(username, password);
                console.log('✅ Real login successful:', response);
                
                // Store real user data
                const user = {
                    id: response.user.id,
                    name: `${response.user.first_name} ${response.user.last_name}`,
                    email: response.user.email,
                    role: response.user.role,
                    loginDate: new Date().toISOString()
                };
                
                // Store in both storages
                sessionStorage.setItem('oceanGuardUser', JSON.stringify(user));
                localStorage.setItem('oceanGuardUser', JSON.stringify(user));
                localStorage.setItem('oceanGuardToken', response.access_token);
                
                // Dispatch login event for navigation update
                window.dispatchEvent(new CustomEvent('userLoggedIn', { detail: user }));
                
                alert('Login successful! Welcome back.');
                
                // Redirect based on role
                if (user.role === 'admin') {
                    window.location.href = 'admin-dashboard.html';
                } else if (user.role === 'rescue_team' || user.role === 'rescue') {
                    window.location.href = 'rescue-console.html';
                } else if (user.role === 'authority') {
                    window.location.href = 'authority-console.html';
                } else {
                    // For public users
                    window.location.href = 'my-reports.html';
                }
                
            } catch (error) {
                console.error('❌ Login failed:', error);
                let errorMsg = `Login failed: ${error.message}\n\n`;
                
                if (error.message.includes('401') || error.message.includes('Invalid credentials')) {
                    errorMsg += 'Try these options:\n\n';
                    errorMsg += 'Quick Demo (no password):\n';
                    errorMsg += '• Username: "user" or "citizen"\n';
                    errorMsg += '• Username: "admin" or "rescue"\n\n';
                    errorMsg += 'Database Accounts:\n';
                    errorMsg += '• demo_citizen / citizen123\n';
                    errorMsg += '• demo_admin / admin123\n';
                    errorMsg += '• demo_rescue / rescue123';
                } else {
                    errorMsg += 'Please check your connection and try again.';
                }
                
                alert(errorMsg);
            }
        });
    }

    // Registration form submission
    if (registerForm) {
        registerForm.addEventListener('submit', async (event) => {
            event.preventDefault();
            
            const formData = new FormData(registerForm);
            const password = formData.get('password');
            const confirmPassword = formData.get('confirm-password');
            
            if (password !== confirmPassword) {
                alert('Passwords do not match!');
                return;
            }
            
            if (password.length < 6) {
                alert('Password must be at least 6 characters long!');
                return;
            }
            
            // Prepare user data for API
            const userData = {
                username: formData.get('email'), // Use email as username
                email: formData.get('email'),
                password: password,
                first_name: formData.get('firstname'),
                last_name: formData.get('lastname'),
                phone: formData.get('phone'),
                location: formData.get('location')
            };
            
            try {
                // Use API client to register user in database
                const api = new OceanHazardAPI();
                console.log('🌊 Attempting registration with API:', userData);
                
                const response = await api.register(userData);
                console.log('✅ Registration successful:', response);
                
                // After registration, login to get token
                console.log('🔐 Logging in to get authentication token...');
                const loginResponse = await api.login(userData.username, userData.password);
                console.log('✅ Login successful:', loginResponse);
                
                // Store user data in both sessionStorage and localStorage for compatibility
                const user = {
                    name: `${userData.first_name} ${userData.last_name}`,
                    email: userData.email,
                    phone: userData.phone,
                    location: userData.location,
                    role: 'public',
                    registrationDate: new Date().toISOString(),
                    id: response.id
                };
                
                // Store in sessionStorage for main page compatibility
                sessionStorage.setItem('oceanGuardUser', JSON.stringify(user));
                
                // Store in localStorage for API client and other pages
                localStorage.setItem('oceanGuardUser', JSON.stringify(user));
                localStorage.setItem('oceanGuardToken', loginResponse.access_token);
                alert('Registration successful! Welcome to Ocean Sentinels! Your account has been saved to the database.');
                window.location.href = 'my-reports.html';
                
            } catch (error) {
                console.error('❌ Registration failed:', error);
                
                // Provide specific error messages
                let errorMessage = error.message;
                if (errorMessage.includes('Username already registered')) {
                    errorMessage = 'This email is already registered. Please use a different email or try logging in.';
                } else if (errorMessage.includes('Email already registered')) {
                    errorMessage = 'This email is already registered. Please use a different email or try logging in.';
                } else if (errorMessage.includes('Network error')) {
                    errorMessage = 'Unable to connect to the server. Please check your internet connection and try again.';
                }
                
                alert(`Registration failed: ${errorMessage}`);
            }
        });
    }

    // Report form submission
    if (reportForm) {
        reportForm.addEventListener('submit', async (event) => {
            event.preventDefault();
            
            const submitBtn = reportForm.querySelector('button[type="submit"]');
            const originalBtnText = submitBtn.innerHTML;
            
            // Disable button and show loading state
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Submitting...';
            
            const referenceId = generateReferenceId();
            const formData = new FormData(reportForm);
            const urgency = document.querySelector('input[name="urgency"]:checked').value;
            
            // Get current location if available
            let location = formData.get('location');
            let latitude = null;
            let longitude = null;
            
            try {
                const currentLocation = await getCurrentLocation();
                if (currentLocation) {
                    const [lat, lng] = currentLocation.split(', ');
                    latitude = parseFloat(lat);
                    longitude = parseFloat(lng);
                    if (!location) {
                        location = currentLocation;
                    }
                }
            } catch (error) {
                console.log('Location not available:', error);
            }
            
            const reportData = {
                hazard_type: formData.get('hazard-type'),
                location: location || 'Unknown Location',
                latitude: latitude,
                longitude: longitude,
                description: formData.get('description'),
                contact_info: formData.get('contact'),
                urgency: urgency.toLowerCase()  // Backend expects lowercase enum values
            };

            try {
                // Use API client to submit report to database
                const api = new OceanHazardAPI();
                console.log('🌊 Submitting incident report:', reportData);
                
                const response = await api.createIncident(reportData);
                console.log('✅ Incident created successfully:', response);
                
                // Also store locally for offline access
                const localReportData = {
                    referenceId: response.reference_id || referenceId,
                    ...reportData,
                    timestamp: new Date().toISOString(),
                    status: 'pending',
                    id: response.id
                };
                
                let reports = JSON.parse(localStorage.getItem('hazardReports') || '[]');
                reports.unshift(localReportData);
                localStorage.setItem('hazardReports', JSON.stringify(reports));

                // Show success message with reference ID
                closeModal(reportModal);
                
                // Re-enable button
                submitBtn.disabled = false;
                submitBtn.innerHTML = originalBtnText;
                
                // Create and show success notification
                const notification = document.createElement('div');
                notification.className = 'success-notification';
                notification.innerHTML = `
                    <div class="notification-content">
                        <i class="fas fa-check-circle"></i>
                        <h3>Report Submitted Successfully!</h3>
                        <p>Your hazard report has been submitted to the authorities and saved to the database.</p>
                        <p><strong>Reference ID: ${response.reference_id || referenceId}</strong></p>
                        <p>Please save this reference ID for tracking your report.</p>
                        <button class="btn btn--primary" onclick="this.parentElement.parentElement.remove()">Close</button>
                    </div>
                `;
                
                document.body.appendChild(notification);
                
                // Clear the form
                reportForm.reset();
                
                // Check if user is logged in to redirect appropriately
                const user = JSON.parse(sessionStorage.getItem('oceanGuardUser'));
                if (user && user.role === 'public') {
                    setTimeout(() => {
                        window.location.href = 'my-reports.html';
                    }, 3000);
                }
                
            } catch (error) {
                console.error('❌ Failed to submit incident:', error);
                
                // Better error message handling
                let errorMessage = 'Unknown error occurred';
                if (error.message) {
                    errorMessage = error.message;
                } else if (error.response && error.response.data) {
                    errorMessage = error.response.data.detail || error.response.data.message || 'Server error';
                } else if (typeof error === 'string') {
                    errorMessage = error;
                } else if (error.toString && error.toString() !== '[object Object]') {
                    errorMessage = error.toString();
                } else {
                    // Network/connection issues
                    errorMessage = 'Unable to connect to server. Please check your internet connection.';
                }
                
                // Fallback to local storage if API fails
                const fallbackReportData = {
                    referenceId: referenceId,
                    ...reportData,
                    timestamp: new Date().toISOString(),
                    status: 'pending'
                };
                
                let reports = JSON.parse(localStorage.getItem('hazardReports') || '[]');
                reports.unshift(fallbackReportData);
                localStorage.setItem('hazardReports', JSON.stringify(reports));
                
                alert(`Report submission failed: ${errorMessage}.\n\nYour report has been saved locally with ID: ${referenceId} and will be submitted when connection is restored.`);
                
                // Still show success for local storage
                closeModal(reportModal);
                
                // Re-enable button
                submitBtn.disabled = false;
                submitBtn.innerHTML = originalBtnText;
                
                reportForm.reset();
            }
        });
    }

    // --- SECTION 8: LOGOUT LOGIC ---

    function logout(e) {
        e.preventDefault();
        // Clear both storage types
        sessionStorage.removeItem('oceanGuardUser');
        localStorage.removeItem('oceanGuardUser');
        localStorage.removeItem('oceanGuardToken');
        
        // Dispatch logout event for navigation update
        window.dispatchEvent(new Event('userLoggedOut'));
        
        alert('You have been logged out.');
        window.location.href = 'index.html';
    }

    // Handle logout button in my-reports.html
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', logout);
    }

    // --- SECTION 9: PROTECTED PAGE LOGIC ---
    
    const currentPage = window.location.pathname.split('/').pop();

    if (currentPage === 'my-reports.html') {
        const user = JSON.parse(localStorage.getItem('oceanGuardUser')) || 
                     JSON.parse(sessionStorage.getItem('oceanGuardUser'));
        if (!user || user.role !== 'public') {
            alert('Access Denied. Please log in as a citizen to view your reports.');
            window.location.href = 'index.html';
        }
    }

    if (currentPage === 'reports.html') {
        const user = JSON.parse(localStorage.getItem('oceanGuardUser')) || 
                     JSON.parse(sessionStorage.getItem('oceanGuardUser'));
        if (!user || !['admin', 'authority', 'rescue_team'].includes(user.role)) {
            alert('Access denied: This page is for authorized personnel only.');
            window.location.href = 'index.html';
        }
    }

    if (currentPage === 'admin-dashboard.html') {
        const user = JSON.parse(localStorage.getItem('oceanGuardUser')) || 
                     JSON.parse(sessionStorage.getItem('oceanGuardUser'));
        if (!user || user.role !== 'admin') {
            alert('Access denied: This page is for administrators only.');
            window.location.href = 'index.html';
        }
    }

    // --- SECTION 10: ROLE-BASED NAVIGATION VISIBILITY ---
    // Navigation is now handled by navigation-manager.js
    // This section is kept for backwards compatibility

    // --- SECTION 11: INITIALIZE LOGIN STATE ON PAGE LOAD ---
    // Check and update login button/user info on page load
    checkLoginState();

});

// Add this to your JavaScript file
function initMiniMap() {
    // Check if Leaflet is available
    if (typeof L === 'undefined') {
        console.warn('Leaflet library not loaded, skipping mini map initialization');
        return;
    }
    
    // Check if mini-map element exists
    const mapElement = document.getElementById('mini-map');
    if (!mapElement) {
        console.warn('mini-map element not found, skipping initialization');
        return;
    }
    
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function(position) {
            const lat = position.coords.latitude;
            const lng = position.coords.longitude;
            
            // Using Leaflet.js for the mini map
            const map = L.map('mini-map', {
                zoomControl: false,
                scrollWheelZoom: false,
                dragging: false
            }).setView([lat, lng], 10);
            
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
            
            // Add user location marker
            L.marker([lat, lng]).addTo(map);
            
            // Add 50km radius circle
            L.circle([lat, lng], {
                color: '#005A9C',
                fillColor: '#005A9C',
                fillOpacity: 0.1,
                radius: 50000 // 50km in meters
            }).addTo(map);
        }, function(error) {
            console.warn('Could not get user location for mini map:', error);
        });
    } else {
        console.warn('Geolocation not supported by this browser');
    }
}

// Defer map initialization to avoid blocking modal interactions
document.addEventListener('DOMContentLoaded', () => {
    // Delay map init by 1 second to ensure smooth page interactions
    setTimeout(initMiniMap, 1000);
});
