/**
 * Role-Based Navigation Manager
 * Shared across all pages to manage navigation visibility
 */

(function() {
    'use strict';

    /**
     * Update navigation visibility based on current user role
     */
    function updateNavigationBasedOnRole() {
        // Check both localStorage and sessionStorage for user data
        let user = null;
        try {
            user = JSON.parse(localStorage.getItem('oceanGuardUser')) || 
                   JSON.parse(sessionStorage.getItem('oceanGuardUser'));
        } catch (e) {
            console.warn('Could not parse user data:', e);
        }

        // Find the navigation reports link
        const navReportsLink = document.getElementById('nav-reports');
        
        if (navReportsLink) {
            // Show "Incident Reports" link only for admin, authority, rescue_team
            if (user && ['admin', 'authority', 'rescue_team'].includes(user.role)) {
                navReportsLink.style.display = 'block';
            } else {
                navReportsLink.style.display = 'none';
            }
        }

        // Show/hide role-specific console links
        const navAdminConsole = document.getElementById('nav-admin-console');
        const navRescueConsole = document.getElementById('nav-rescue-console');
        const navAuthorityConsole = document.getElementById('nav-authority-console');

        // Hide all console links first
        if (navAdminConsole) navAdminConsole.style.display = 'none';
        if (navRescueConsole) navRescueConsole.style.display = 'none';
        if (navAuthorityConsole) navAuthorityConsole.style.display = 'none';

        if (user) {
            switch (user.role) {
                case 'admin':
                    if (navAdminConsole) navAdminConsole.style.display = 'block';
                    break;
                case 'rescue_team':
                    if (navRescueConsole) navRescueConsole.style.display = 'block';
                    break;
                case 'authority':
                    if (navAuthorityConsole) navAuthorityConsole.style.display = 'block';
                    break;
            }
        }

        // Update user welcome message if present
        const welcomeMessage = document.getElementById('welcome-message');
        if (welcomeMessage && user) {
            welcomeMessage.textContent = `Welcome, ${user.name || user.username || 'User'}`;
        }
    }

    /**
     * Initialize navigation on page load
     */
    function initNavigation() {
        // Update navigation immediately
        updateNavigationBasedOnRole();

        // Listen for storage changes (e.g., when user logs in on another tab)
        window.addEventListener('storage', function(e) {
            if (e.key === 'oceanGuardUser' || e.key === null) {
                updateNavigationBasedOnRole();
            }
        });

        // Listen for custom login event
        window.addEventListener('userLoggedIn', function(e) {
            updateNavigationBasedOnRole();
        });

        // Listen for custom logout event
        window.addEventListener('userLoggedOut', function() {
            updateNavigationBasedOnRole();
        });
    }

    // Export to global scope
    window.updateNavigationBasedOnRole = updateNavigationBasedOnRole;
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initNavigation);
    } else {
        initNavigation();
    }
})();
