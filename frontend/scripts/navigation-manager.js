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
                
                // Set the correct destination based on user role
                const linkElement = navReportsLink.querySelector('a');
                if (linkElement) {
                    if (user.role === 'admin') {
                        linkElement.href = 'admin-dashboard.html';
                        linkElement.textContent = 'Admin Dashboard';
                        console.log('✅ Admin logged in - showing Admin Dashboard link, href:', linkElement.href);
                    } else {
                        linkElement.href = 'reports.html';
                        linkElement.textContent = 'Incident Reports';
                        console.log('✅ Showing Incident Reports link for role:', user.role, 'href:', linkElement.href);
                    }
                } else {
                    console.error('❌ Could not find <a> element inside nav-reports');
                }
            } else {
                navReportsLink.style.display = 'none';
                console.log('❌ Hiding Incident Reports link. User role:', user?.role || 'not logged in');
            }
        } else {
            console.warn('Navigation reports link (#nav-reports) not found on this page');
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
                console.log('Storage changed, updating navigation...');
                updateNavigationBasedOnRole();
            }
        });

        // Listen for custom login event
        window.addEventListener('userLoggedIn', function(e) {
            console.log('User logged in event received:', e.detail);
            updateNavigationBasedOnRole();
        });

        // Listen for custom logout event
        window.addEventListener('userLoggedOut', function() {
            console.log('User logged out event received');
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

    console.log('🧭 Navigation manager loaded');
})();
