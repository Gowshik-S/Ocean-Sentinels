/**
 * Admin Dashboard - Ocean Guard
 * Manages rescue teams and authorities
 */

class AdminDashboard {
    constructor() {
        this.api = new OceanHazardAPI();
        this.teams = [];
        this.authorities = [];
        this.currentUser = null;
    }

    async init() {
        try {
            // Check authentication and admin access
            await this.checkAdminAccess();
            
            // Load data
            await this.loadData();
            
            // Setup event listeners
            this.setupEventListeners();
            
        } catch (error) {
            console.error('❌ Failed to initialize admin dashboard:', error);
            this.showAccessDenied();
        }
    }

    async checkAdminAccess() {
        console.log('🔍 Checking admin access...');
        
        const token = localStorage.getItem('oceanGuardToken');
        console.log('Token found:', token ? 'Yes' : 'No');
        
        if (!token) {
            console.log('❌ No authentication token found');
            throw new Error('No authentication token found');
        }

        try {
            console.log('🔄 Fetching current user...');
            this.currentUser = await this.api.getCurrentUser();
            console.log('✅ Current user retrieved:', this.currentUser);
            console.log('User role type:', typeof this.currentUser.role, 'Value:', this.currentUser.role);
            
            // Check if user has admin role - database uses UPPERCASE, backend might return either
            const userRole = this.currentUser.role;
            const isAdmin = userRole === 'ADMIN' || userRole === 'admin' || userRole === 'Admin';
            
            console.log('Is admin check:', isAdmin, 'for role:', userRole);
            
            if (!this.currentUser || !isAdmin) {
                console.log('❌ Access denied. User role:', userRole, 'Expected: ADMIN or admin');
                throw new Error('Access denied: Admin privileges required');
            }
            
            console.log('✅ Admin access granted for role:', userRole);
            
            // Update welcome message
            const welcomeMessage = document.getElementById('welcome-message');
            if (welcomeMessage) {
                const fullName = `${this.currentUser.first_name || ''} ${this.currentUser.last_name || ''}`.trim();
                welcomeMessage.textContent = `Welcome, ${fullName || this.currentUser.username}`;
            }
            
        } catch (error) {
            console.error('❌ checkAdminAccess error:', error);
            throw new Error('Invalid token or insufficient privileges');
        }
    }

    showAccessDenied() {
        document.getElementById('admin-content').style.display = 'none';
        document.getElementById('access-denied').style.display = 'block';
    }

    showErrorNotification(message) {
        console.error('Error notification:', message);
        
        // Create or update error notification
        let errorDiv = document.getElementById('error-notification');
        if (!errorDiv) {
            errorDiv = document.createElement('div');
            errorDiv.id = 'error-notification';
            errorDiv.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: #f8d7da;
                color: #721c24;
                padding: 15px;
                border-radius: 4px;
                border: 1px solid #f5c6cb;
                max-width: 400px;
                z-index: 9999;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            `;
            document.body.appendChild(errorDiv);
        }
        
        errorDiv.innerHTML = `
            <strong>⚠️ Error:</strong><br>
            ${message}
            <button onclick="this.parentElement.remove()" style="float: right; background: none; border: none; font-size: 18px; cursor: pointer;">×</button>
        `;
        
        // Auto-remove after 10 seconds
        setTimeout(() => {
            if (errorDiv.parentElement) {
                errorDiv.remove();
            }
        }, 10000);
    }

    showSuccessNotification(message) {
        console.log('Success notification:', message);
        
        // Create or update success notification
        let successDiv = document.getElementById('success-notification');
        if (!successDiv) {
            successDiv = document.createElement('div');
            successDiv.id = 'success-notification';
            successDiv.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                background: #d4edda;
                color: #155724;
                padding: 15px;
                border-radius: 4px;
                border: 1px solid #c3e6cb;
                max-width: 400px;
                z-index: 9999;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            `;
            document.body.appendChild(successDiv);
        }
        
        successDiv.innerHTML = `
            <strong>✅ Success:</strong><br>
            ${message}
            <button onclick="this.parentElement.remove()" style="float: right; background: none; border: none; font-size: 18px; cursor: pointer;">×</button>
        `;
        
        // Auto-remove after 8 seconds
        setTimeout(() => {
            if (successDiv.parentElement) {
                successDiv.remove();
            }
        }, 8000);
    }

    async loadData() {
        await this.loadTeams();
        await this.loadAuthorities();
        await this.loadStatistics();
    }

    async loadTeams() {
        try {
            console.log('📊 Loading teams from database...');
            
            // Get users data using the API client method (with fallback for browser cache)
            let usersData = [];
            try {
                if (typeof this.api.getUsers === 'function') {
                    usersData = await this.api.getUsers();
                } else {
                    console.warn('⚠️ getUsers method not found, using direct fetch (browser cache issue)');
                    const response = await fetch(`${this.api.baseURL}/users/`, {
                        headers: this.api.getHeaders()
                    });
                    if (response.ok) {
                        usersData = await response.json();
                    } else {
                        throw new Error(`Users API failed: ${response.status} - ${response.statusText}`);
                    }
                }
            } catch (fetchError) {
                console.error('❌ Failed to fetch users:', fetchError.message);
                throw fetchError;
            }
            
            console.log(`Found ${usersData.length} total users in database`);
            
            const rescueTeamUsers = usersData.filter(user => 
                user.role === 'RESCUE_TEAM' || user.role === 'rescue_team'
            );
            console.log(`Found ${rescueTeamUsers.length} rescue team users in database`);
            
            // Transform user data to team format
            this.teams = rescueTeamUsers.map(user => ({
                id: user.id,
                name: `${user.first_name} ${user.last_name}`,
                leader: `${user.first_name} ${user.last_name}`,
                email: user.email,
                phone: user.phone || 'Not provided',
                location: user.location || 'Not specified',
                type: "rescue-team",
                status: user.is_active ? 'active' : 'inactive',
                equipment: "Standard rescue equipment",
                created_at: user.created_at
            }));
            
            this.renderTeamsList();
            
        } catch (error) {
            console.error('❌ Failed to load teams from database:', error);
            this.teams = [];
            this.renderTeamsList();
            
            // Show an error message to user
            const teamsList = document.getElementById('teams-list');
            if (teamsList) {
                teamsList.innerHTML = `
                    <div style="text-align: center; padding: 20px; color: #6c757d;">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p>Unable to load rescue teams from database.</p>
                        <p style="font-size: 14px;">Error: ${error.message}</p>
                    </div>
                `;
            }
            
            this.showErrorNotification(`Failed to load teams: ${error.message}`);
        }
    }

    async loadAuthorities() {
        try {
            console.log('📊 Loading authorities from database...');
            
            // Get users data using the API client method (with fallback for browser cache)
            let usersData = [];
            try {
                if (typeof this.api.getUsers === 'function') {
                    usersData = await this.api.getUsers();
                } else {
                    console.warn('⚠️ getUsers method not found, using direct fetch (browser cache issue)');
                    const response = await fetch(`${this.api.baseURL}/users/`, {
                        headers: this.api.getHeaders()
                    });
                    if (response.ok) {
                        usersData = await response.json();
                    } else {
                        throw new Error(`Users API failed: ${response.status} - ${response.statusText}`);
                    }
                }
            } catch (fetchError) {
                console.error('❌ Failed to fetch users:', fetchError.message);
                throw fetchError;
            }
            
            console.log(`Found ${usersData.length} total users in database`);
            
            const authorityUsers = usersData.filter(user => 
                user.role === 'AUTHORITY' || user.role === 'authority'
            );
            console.log(`Found ${authorityUsers.length} authority users in database`);
            
            // Transform user data to authority format
            this.authorities = authorityUsers.map(user => ({
                id: user.id,
                name: `${user.first_name} ${user.last_name}`,
                position: "Authority Officer",
                email: user.email,
                phone: user.phone || 'Not provided',
                department: "Ocean Guard Authority",
                level: "state",
                status: user.is_active ? 'active' : 'inactive',
                jurisdiction: user.location || 'Regional operations',
                created_at: user.created_at
            }));
            
            this.renderAuthoritiesList();
            
        } catch (error) {
            console.error('❌ Failed to load authorities from database:', error);
            this.authorities = [];
            this.renderAuthoritiesList();
            
            // Show an error message to user
            const authoritiesList = document.getElementById('authorities-list');
            if (authoritiesList) {
                authoritiesList.innerHTML = `
                    <div style="text-align: center; padding: 20px; color: #6c757d;">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p>Unable to load authorities from database.</p>
                        <p style="font-size: 14px;">Error: ${error.message}</p>
                    </div>
                `;
            }
            
            this.showErrorNotification(`Failed to load authorities: ${error.message}`);
        }
    }

    async loadStatistics() {
        try {
            console.log('📊 Loading statistics from database...');
            
            // Get analytics data from backend using the correct API method
            console.log('🔄 Fetching analytics data...');
            const analyticsData = await this.api.getDashboardAnalytics();
            console.log('✅ Analytics data received:', analyticsData);
            
            // Try to get users data using the cleaner API method (with fallback)
            console.log('🔄 Fetching users data...');
            let usersData = [];
            
            try {
                if (typeof this.api.getUsers === 'function') {
                    usersData = await this.api.getUsers();
                } else {
                    console.warn('⚠️ getUsers method not found, using direct fetch (browser cache issue)');
                    const response = await fetch(`${this.api.baseURL}/users/`, {
                        headers: this.api.getHeaders()
                    });
                    if (response.ok) {
                        usersData = await response.json();
                    } else {
                        throw new Error(`Users API failed: ${response.status}`);
                    }
                }
                console.log(`✅ Found ${usersData.length} total users in database`);
            } catch (userError) {
                console.warn('❌ Could not fetch users data:', userError.message);
                usersData = [];
            }
            
            // Filter users by role (handle both UPPERCASE and lowercase)
            const rescueTeams = usersData.filter(user => 
                user.role === 'RESCUE_TEAM' || user.role === 'rescue_team'
            );
            const authorities = usersData.filter(user => 
                user.role === 'AUTHORITY' || user.role === 'authority'
            );
            const activeTeams = rescueTeams.filter(user => user.is_active);
            
            console.log(`Statistics: ${rescueTeams.length} rescue teams, ${activeTeams.length} active teams, ${authorities.length} authorities`);
            
            // Update statistics display with real data
            document.getElementById('total-teams').textContent = rescueTeams.length;
            document.getElementById('active-teams').textContent = activeTeams.length;
            document.getElementById('total-authorities').textContent = authorities.length;
            document.getElementById('total-incidents').textContent = analyticsData.total_incidents || 0;
            
            console.log('✅ Statistics updated with database data');
            
        } catch (error) {
            console.error('❌ Failed to load statistics from database:', error);
            console.error('Error details:', error.message);
            console.error('Error stack:', error.stack);
            
            // Show specific error information
            const errorMsg = error.message || 'Unknown error';
            document.getElementById('total-teams').textContent = 'Error';
            document.getElementById('active-teams').textContent = 'Error';
            document.getElementById('total-authorities').textContent = 'Error';
            document.getElementById('total-incidents').textContent = 'Error';
            
            // Show error notification to user
            this.showErrorNotification(`Failed to load statistics: ${errorMsg}`);
        }
    }

    getDefaultTeams() {
        return [
            {
                id: 1,
                name: "Chennai Marine Rescue Unit",
                leader: "Captain Rajesh Kumar",
                email: "cmru@coastguard.gov.in",
                phone: "+91 9876543210",
                location: "Chennai Port, Tamil Nadu",
                type: "coast-guard",
                status: "active",
                equipment: "Rescue boats, diving equipment, medical supplies, communication systems",
                created_at: new Date().toISOString()
            },
            {
                id: 2,
                name: "Mumbai Emergency Response Team",
                leader: "Commander Priya Sharma",
                email: "mert@mumbaiport.gov.in",
                phone: "+91 9876543211",
                location: "Mumbai Port, Maharashtra",
                type: "emergency-response",
                status: "on-duty",
                equipment: "Fast response boats, helicopter support, medical team, rescue equipment",
                created_at: new Date().toISOString()
            },
            {
                id: 3,
                name: "Goa Coastal Safety Unit",
                leader: "Lt. Commander Suresh Patil",
                email: "gcsu@goacoastguard.gov.in",
                phone: "+91 9876543212",
                location: "Panaji, Goa",
                type: "marine-rescue",
                status: "active",
                equipment: "Patrol boats, jet skis, life saving equipment, first aid",
                created_at: new Date().toISOString()
            }
        ];
    }

    getDefaultAuthorities() {
        return [
            {
                id: 1,
                name: "Dr. Vikram Singh",
                position: "Director General",
                email: "dg@coastguard.gov.in",
                phone: "+91 11-23386100",
                department: "Indian Coast Guard",
                level: "national",
                status: "active",
                jurisdiction: "National maritime security and rescue operations",
                created_at: new Date().toISOString()
            },
            {
                id: 2,
                name: "Smt. Kavitha Nair",
                position: "Disaster Management Coordinator",
                email: "coordinator@ndma.gov.in",
                phone: "+91 11-26701700",
                department: "National Disaster Management Authority",
                level: "national",
                status: "on-call",
                jurisdiction: "National disaster response coordination",
                created_at: new Date().toISOString()
            },
            {
                id: 3,
                name: "Shri Ramesh Chandra",
                position: "Port Authority Chairman",
                email: "chairman@mumbaiport.gov.in",
                phone: "+91 22-26572000",
                department: "Mumbai Port Trust",
                level: "state",
                status: "active",
                jurisdiction: "Mumbai port operations and marine safety",
                created_at: new Date().toISOString()
            }
        ];
    }

    setupEventListeners() {
        // Add Team Form
        document.getElementById('add-team-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addTeam();
        });

        // Add Authority Form
        document.getElementById('add-authority-form').addEventListener('submit', (e) => {
            e.preventDefault();
            this.addAuthority();
        });

        // Logout
        document.getElementById('logout-btn').addEventListener('click', (e) => {
            e.preventDefault();
            this.logout();
        });
    }

    async addTeam() {
        try {
            console.log('🔄 Adding new rescue team...');
            
            // Get form data
            const teamData = {
                username: document.getElementById('team-email').value.trim(), // Use email as username and trim
                email: document.getElementById('team-email').value.trim(),
                password: 'Ocean@123', // Default password - team can change it later
                first_name: document.getElementById('team-name').value.trim().split(' ')[0] || document.getElementById('team-name').value.trim(),
                last_name: document.getElementById('team-name').value.trim().split(' ').slice(1).join(' ') || '',
                phone: document.getElementById('team-phone').value.trim(),
                location: document.getElementById('team-location').value.trim(),
                role: 'rescue_team' // Use lowercase as expected by backend enum
            };

            console.log('Team data to create:', teamData);

            // Call API to create user
            const response = await this.api.createUser(teamData);
            console.log('✅ Rescue team created successfully:', response);

            // Reset form
            document.getElementById('add-team-form').reset();
            
            // Reload data to show the new team
            await this.loadTeams();
            await this.loadStatistics();
            
            this.showSuccessNotification('✅ Rescue team added successfully! Default password: Ocean@123');
        } catch (error) {
            console.error('❌ Failed to add rescue team:', error);
            this.showErrorNotification(`Failed to add rescue team: ${error.message}`);
        }
    }

    async addAuthority() {
        try {
            console.log('🔄 Adding new authority...');
            
            // Get form data
            const authorityData = {
                username: document.getElementById('authority-email').value.trim(), // Use email as username and trim
                email: document.getElementById('authority-email').value.trim(),
                password: 'Ocean@123', // Default password - authority can change it later
                first_name: document.getElementById('authority-name').value.trim().split(' ')[0] || document.getElementById('authority-name').value.trim(),
                last_name: document.getElementById('authority-name').value.trim().split(' ').slice(1).join(' ') || '',
                phone: document.getElementById('authority-phone').value.trim(),
                location: document.getElementById('authority-department').value.trim(), // Using department as location
                role: 'authority' // Use lowercase as expected by backend enum
            };

            console.log('Authority data to create:', authorityData);

            // Call API to create user
            const response = await this.api.createUser(authorityData);
            console.log('✅ Authority created successfully:', response);

            // Reset form
            document.getElementById('add-authority-form').reset();
            
            // Reload data to show the new authority
            await this.loadAuthorities();
            await this.loadStatistics();
            
            this.showSuccessNotification('✅ Authority added successfully! Default password: Ocean@123');
        } catch (error) {
            console.error('❌ Failed to add authority:', error);
            this.showErrorNotification(`Failed to add authority: ${error.message}`);
        }
    }

    renderTeamsList() {
        const container = document.getElementById('teams-list');
        
        if (this.teams.length === 0) {
            container.innerHTML = '<p class="text-center">No rescue teams found. Add a team to get started.</p>';
            return;
        }

        let html = '';
        this.teams.forEach(team => {
            const statusClass = this.getStatusClass(team.status);
            html += `
                <div class="team-item">
                    <div class="team-info">
                        <h4>${team.name}</h4>
                        <p><strong>Leader:</strong> ${team.leader}</p>
                        <p><strong>Type:</strong> ${this.formatTeamType(team.type)} | <strong>Location:</strong> ${team.location}</p>
                        <p><strong>Contact:</strong> ${team.email} | ${team.phone}</p>
                        <p><strong>Equipment:</strong> ${team.equipment}</p>
                        <span class="status-badge ${statusClass}">${team.status.toUpperCase()}</span>
                    </div>
                    <div class="team-actions">
                        <button class="admin-btn" onclick="adminDashboard.editTeam(${team.id})">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="admin-btn danger" onclick="adminDashboard.deleteTeam(${team.id})">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </div>
            `;
        });

        container.innerHTML = html;
    }

    renderAuthoritiesList() {
        const container = document.getElementById('authorities-list');
        
        if (this.authorities.length === 0) {
            container.innerHTML = '<p class="text-center">No authorities found. Add an authority to get started.</p>';
            return;
        }

        let html = '';
        this.authorities.forEach(authority => {
            const statusClass = this.getStatusClass(authority.status);
            html += `
                <div class="authority-item">
                    <div class="team-info">
                        <h4>${authority.name}</h4>
                        <p><strong>Position:</strong> ${authority.position}</p>
                        <p><strong>Department:</strong> ${authority.department} | <strong>Level:</strong> ${this.formatAuthorityLevel(authority.level)}</p>
                        <p><strong>Contact:</strong> ${authority.email} | ${authority.phone}</p>
                        <p><strong>Jurisdiction:</strong> ${authority.jurisdiction}</p>
                        <span class="status-badge ${statusClass}">${authority.status.toUpperCase()}</span>
                    </div>
                    <div class="team-actions">
                        <button class="admin-btn" onclick="adminDashboard.editAuthority(${authority.id})">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="admin-btn danger" onclick="adminDashboard.deleteAuthority(${authority.id})">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </div>
            `;
        });

        container.innerHTML = html;
    }

    getStatusClass(status) {
        switch(status) {
            case 'active': return 'status-active';
            case 'on-duty': case 'on-call': return 'status-on-duty';
            default: return 'status-inactive';
        }
    }

    formatTeamType(type) {
        return type.split('-').map(word => 
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ');
    }

    formatAuthorityLevel(level) {
        return level.split('-').map(word => 
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ');
    }

    editTeam(teamId) {
        const team = this.teams.find(t => t.id === teamId);
        if (team) {
            // Fill form with existing data
            document.getElementById('team-name').value = team.name;
            document.getElementById('team-leader').value = team.leader;
            document.getElementById('team-email').value = team.email;
            document.getElementById('team-phone').value = team.phone;
            document.getElementById('team-location').value = team.location;
            document.getElementById('team-type').value = team.type;
            document.getElementById('team-status').value = team.status;
            document.getElementById('team-equipment').value = team.equipment;
            
            // Remove team for re-adding with updates
            this.deleteTeam(teamId, false);
            
            // Scroll to form
            document.getElementById('add-team-form').scrollIntoView({ behavior: 'smooth' });
        }
    }

    editAuthority(authorityId) {
        const authority = this.authorities.find(a => a.id === authorityId);
        if (authority) {
            // Fill form with existing data
            document.getElementById('authority-name').value = authority.name;
            document.getElementById('authority-position').value = authority.position;
            document.getElementById('authority-email').value = authority.email;
            document.getElementById('authority-phone').value = authority.phone;
            document.getElementById('authority-department').value = authority.department;
            document.getElementById('authority-level').value = authority.level;
            document.getElementById('authority-status').value = authority.status;
            document.getElementById('authority-jurisdiction').value = authority.jurisdiction;
            
            // Remove authority for re-adding with updates
            this.deleteAuthority(authorityId, false);
            
            // Scroll to form
            document.getElementById('add-authority-form').scrollIntoView({ behavior: 'smooth' });
        }
    }

    deleteTeam(teamId, confirm = true) {
        if (confirm && !window.confirm('Are you sure you want to delete this rescue team member? This action cannot be undone.')) {
            return;
        }

        // Call backend API to delete the user
        this.api.deleteUser(teamId)
            .then(response => {
                console.log('✅ Rescue team member deleted:', response);
                
                // Remove from local array
                this.teams = this.teams.filter(team => team.id !== teamId);
                
                // Update UI
                this.renderTeamsList();
                this.loadStatistics();
                
                if (confirm) {
                    this.showSuccessNotification(`✅ Rescue team member deleted successfully!`);
                }
            })
            .catch(error => {
                console.error('❌ Failed to delete rescue team member:', error);
                this.showErrorNotification(`Failed to delete rescue team member: ${error.message}`);
            });
    }

    deleteAuthority(authorityId, confirm = true) {
        if (confirm && !window.confirm('Are you sure you want to delete this authority member? This action cannot be undone.')) {
            return;
        }

        // Call backend API to delete the user
        this.api.deleteUser(authorityId)
            .then(response => {
                console.log('✅ Authority member deleted:', response);
                
                // Remove from local array
                this.authorities = this.authorities.filter(authority => authority.id !== authorityId);
                
                // Update UI
                this.renderAuthoritiesList();
                this.loadStatistics();
                
                if (confirm) {
                    this.showSuccessNotification(`✅ Authority member deleted successfully!`);
                }
            })
            .catch(error => {
                console.error('❌ Failed to delete authority member:', error);
                this.showErrorNotification(`Failed to delete authority member: ${error.message}`);
            });
    }

    logout() {
        localStorage.removeItem('oceanGuardToken');
        window.location.href = 'index.html';
    }
}

// Initialize admin dashboard
const adminDashboard = new AdminDashboard();

// Start the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    adminDashboard.init();
});