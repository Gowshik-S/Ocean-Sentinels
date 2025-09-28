// Wait for the entire HTML document to be loaded before running the script
document.addEventListener('DOMContentLoaded', () => {

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
            modal.style.display = 'block';
            document.body.style.overflow = 'hidden';
        }
    }

    function closeModal(modal) {
        if (modal) {
            modal.style.display = 'none';
            document.body.style.overflow = 'auto';
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
            const modal = button.closest('.modal');
            closeModal(modal);
        });
    });

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
        const user = JSON.parse(sessionStorage.getItem('oceanGuardUser'));

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
                    <a href="reports.html" class="btn btn--primary">Admin Dashboard</a>
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
        loginForm.addEventListener('submit', (event) => {
            event.preventDefault();
            const username = document.getElementById('login-username').value;

            let user = null;
            let redirectTo = '';

            if (username.toLowerCase() === 'user' || username.toLowerCase() === 'citizen') {
                user = { name: 'Gowshik S.', role: 'public' };
                redirectTo = 'my-reports.html';
            } else if (username.toLowerCase() === 'admin' || username.toLowerCase() === 'rescue') {
                user = { name: 'Admin', role: 'admin' };
                redirectTo = 'reports.html';
            }

            if (user) {
                sessionStorage.setItem('oceanGuardUser', JSON.stringify(user));
                alert('Login successful! Redirecting...');
                window.location.href = redirectTo;
            } else {
                alert('Login failed. Please use "user"/"citizen" for public access or "admin"/"rescue" for professional access.');
            }
        });
    }

    // Registration form submission
    if (registerForm) {
        registerForm.addEventListener('submit', (event) => {
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
            
            const userData = {
                name: `${formData.get('firstname')} ${formData.get('lastname')}`,
                email: formData.get('email'),
                phone: formData.get('phone'),
                location: formData.get('location'),
                role: 'public',
                registrationDate: new Date().toISOString()
            };
            
            // In a real app, this would go to a server
            sessionStorage.setItem('oceanGuardUser', JSON.stringify(userData));
            alert('Registration successful! Welcome to Ocean Guard!');
            window.location.href = 'my-reports.html';
        });
    }

    // Report form submission
    if (reportForm) {
        reportForm.addEventListener('submit', (event) => {
            event.preventDefault();
            
            const referenceId = generateReferenceId();
            const formData = new FormData(reportForm);
            const urgency = document.querySelector('input[name="urgency"]:checked').value;
            
            const reportData = {
                referenceId: referenceId,
                hazardType: formData.get('hazard-type'),
                location: formData.get('location'),
                description: formData.get('description'),
                contact: formData.get('contact'),
                urgency: urgency,
                timestamp: new Date().toISOString(),
                status: 'pending'
            };

            // Store the report
            let reports = JSON.parse(localStorage.getItem('hazardReports') || '[]');
            reports.unshift(reportData); // Add to beginning of array
            localStorage.setItem('hazardReports', JSON.stringify(reports));

            // Show success message with reference ID
            closeModal(reportModal);
            
            // Create and show success notification
            const notification = document.createElement('div');
            notification.className = 'success-notification';
            notification.innerHTML = `
                <div class="notification-content">
                    <i class="fas fa-check-circle"></i>
                    <h3>Report Submitted Successfully!</h3>
                    <p>Your hazard report has been submitted to the authorities.</p>
                    <p><strong>Reference ID: ${referenceId}</strong></p>
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
        });
    }

    // --- SECTION 8: LOGOUT LOGIC ---

    function logout(e) {
        e.preventDefault();
        sessionStorage.removeItem('oceanGuardUser');
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
        const user = JSON.parse(sessionStorage.getItem('oceanGuardUser'));
        if (!user || user.role !== 'public') {
            alert('Access Denied. Please log in as a citizen to view your reports.');
            window.location.href = 'index.html';
        }
    }

    if (currentPage === 'reports.html') {
        const user = JSON.parse(sessionStorage.getItem('oceanGuardUser'));
        if (!user || user.role !== 'admin') {
            alert('Access Denied. This is a professional portal. Please log in with admin credentials.');
            window.location.href = 'index.html';
        }
    }

    // --- INITIALIZE THE PAGE ---
    checkLoginState();
});
// Add this to your JavaScript file
function initMiniMap() {
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
        });
    }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', initMiniMap);
