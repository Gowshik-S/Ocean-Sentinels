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
        const token = localStorage.getItem('oceanGuardToken');
        if (!token) {
            throw new Error('No authentication token found');
        }

        try {
            this.currentUser = await this.api.getCurrentUser();
            
            // Check if user has admin role
            if (!this.currentUser || this.currentUser.role !== 'admin') {
                throw new Error('Access denied: Admin privileges required');
            }
            
            // Update welcome message
            const welcomeMessage = document.getElementById('welcome-message');
            if (welcomeMessage) {
                welcomeMessage.textContent = `Welcome, ${this.currentUser.full_name || this.currentUser.username}`;
            }
            
        } catch (error) {
            throw new Error('Invalid token or insufficient privileges');
        }
    }

    showAccessDenied() {
        document.getElementById('admin-content').style.display = 'none';
        document.getElementById('access-denied').style.display = 'block';
    }

    async loadData() {
        await this.loadTeams();
        await this.loadAuthorities();
        await this.loadStatistics();
    }

    async loadTeams() {
        try {
            // In a real system, this would be an API call
            // For now, we'll use localStorage or mock data
            const savedTeams = localStorage.getItem('rescueTeams');
            this.teams = savedTeams ? JSON.parse(savedTeams) : this.getDefaultTeams();
            
            this.renderTeamsList();
        } catch (error) {
            console.error('Failed to load teams:', error);
            this.teams = this.getDefaultTeams();
            this.renderTeamsList();
        }
    }

    async loadAuthorities() {
        try {
            const savedAuthorities = localStorage.getItem('authorities');
            this.authorities = savedAuthorities ? JSON.parse(savedAuthorities) : this.getDefaultAuthorities();
            
            this.renderAuthoritiesList();
        } catch (error) {
            console.error('Failed to load authorities:', error);
            this.authorities = this.getDefaultAuthorities();
            this.renderAuthoritiesList();
        }
    }

    async loadStatistics() {
        const activeTeams = this.teams.filter(team => team.status === 'active' || team.status === 'on-duty').length;
        
        document.getElementById('total-teams').textContent = this.teams.length;
        document.getElementById('active-teams').textContent = activeTeams;
        document.getElementById('total-authorities').textContent = this.authorities.length;
        document.getElementById('total-incidents').textContent = '12'; // This would come from API
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
        const formData = {
            id: Date.now(), // Simple ID generation
            name: document.getElementById('team-name').value,
            leader: document.getElementById('team-leader').value,
            email: document.getElementById('team-email').value,
            phone: document.getElementById('team-phone').value,
            location: document.getElementById('team-location').value,
            type: document.getElementById('team-type').value,
            status: document.getElementById('team-status').value,
            equipment: document.getElementById('team-equipment').value,
            created_at: new Date().toISOString()
        };

        try {
            this.teams.push(formData);
            localStorage.setItem('rescueTeams', JSON.stringify(this.teams));
            
            // Reset form
            document.getElementById('add-team-form').reset();
            
            // Refresh display
            this.renderTeamsList();
            this.loadStatistics();
            
            alert('✅ Rescue team added successfully!');
        } catch (error) {
            console.error('Failed to add team:', error);
            alert('❌ Failed to add rescue team. Please try again.');
        }
    }

    async addAuthority() {
        const formData = {
            id: Date.now(),
            name: document.getElementById('authority-name').value,
            position: document.getElementById('authority-position').value,
            email: document.getElementById('authority-email').value,
            phone: document.getElementById('authority-phone').value,
            department: document.getElementById('authority-department').value,
            level: document.getElementById('authority-level').value,
            status: document.getElementById('authority-status').value,
            jurisdiction: document.getElementById('authority-jurisdiction').value,
            created_at: new Date().toISOString()
        };

        try {
            this.authorities.push(formData);
            localStorage.setItem('authorities', JSON.stringify(this.authorities));
            
            // Reset form
            document.getElementById('add-authority-form').reset();
            
            // Refresh display
            this.renderAuthoritiesList();
            this.loadStatistics();
            
            alert('✅ Authority added successfully!');
        } catch (error) {
            console.error('Failed to add authority:', error);
            alert('❌ Failed to add authority. Please try again.');
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
        if (confirm && !window.confirm('Are you sure you want to delete this rescue team?')) {
            return;
        }

        this.teams = this.teams.filter(team => team.id !== teamId);
        localStorage.setItem('rescueTeams', JSON.stringify(this.teams));
        
        this.renderTeamsList();
        this.loadStatistics();
        
        if (confirm) {
            alert('✅ Rescue team deleted successfully!');
        }
    }

    deleteAuthority(authorityId, confirm = true) {
        if (confirm && !window.confirm('Are you sure you want to delete this authority?')) {
            return;
        }

        this.authorities = this.authorities.filter(authority => authority.id !== authorityId);
        localStorage.setItem('authorities', JSON.stringify(this.authorities));
        
        this.renderAuthoritiesList();
        this.loadStatistics();
        
        if (confirm) {
            alert('✅ Authority deleted successfully!');
        }
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