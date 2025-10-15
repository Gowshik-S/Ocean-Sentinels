/**
 * Ocean Hazard API Client
 * Handles all API communication with FastAPI backend
 */

class OceanHazardAPI {
    constructor(baseURL = 'https://ocean-hazard-1-6j5g.onrender.com/api') {
        this.baseURL = baseURL;
        
        // Check both localStorage and sessionStorage for token and user
        this.token = localStorage.getItem('oceanGuardToken') || sessionStorage.getItem('oceanGuardToken');
        this.user = JSON.parse(localStorage.getItem('oceanGuardUser') || sessionStorage.getItem('oceanGuardUser') || 'null');
        
        // If we have a user but no token, try to create a mock token for compatibility
        if (this.user && !this.token) {
            this.token = `mock-token-${this.user.role || 'public'}-${Date.now()}`;
        }
    }

    // Helper method to get headers with auth token
    getHeaders() {
        const headers = {
            'Content-Type': 'application/json',
        };
        
        if (this.token) {
            headers['Authorization'] = `Bearer ${this.token}`;
        }
        
        return headers;
    }

    // Helper method to handle API responses
    async handleResponse(response) {
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ detail: 'Unknown error' }));
            
            // Enhanced error handling for authentication issues
            if (response.status === 401) {
                // Clear invalid tokens
                this.token = null;
                this.user = null;
                localStorage.removeItem('oceanGuardToken');
                localStorage.removeItem('oceanGuardUser');
                sessionStorage.removeItem('oceanGuardToken');
                sessionStorage.removeItem('oceanGuardUser');
            }
            
            // Better error message formatting for 422 validation errors
            let errorMessage;
            if (response.status === 422 && errorData.detail && Array.isArray(errorData.detail)) {
                // Handle FastAPI validation errors
                errorMessage = errorData.detail.map(err => `${err.loc?.join('.')}: ${err.msg}`).join(', ');
            } else {
                errorMessage = errorData.detail || errorData.message || `HTTP ${response.status}: ${response.statusText}`;
            }
            
            console.error('API Error Response:', errorData);
            throw new Error(errorMessage);
        }
        return await response.json();
    }

    // Authentication methods
    async login(username, password) {
        const formData = new FormData();
        formData.append('username', username);
        formData.append('password', password);

        const response = await fetch(`${this.baseURL}/auth/login`, {
            method: 'POST',
            body: formData
        });

        const data = await this.handleResponse(response);
        
        // Store token and user data
        this.token = data.access_token;
        this.user = data.user;
        localStorage.setItem('oceanGuardToken', this.token);
        localStorage.setItem('oceanGuardUser', JSON.stringify(this.user));
        
        return data;
    }

    async register(userData) {
        console.log('🌊 Ocean Guard Registration Attempt:', userData);
        console.log('🔗 API URL:', `${this.baseURL}/auth/register`);
        
        try {
            const response = await fetch(`${this.baseURL}/auth/register`, {
                method: 'POST',
                headers: this.getHeaders(),
                body: JSON.stringify(userData)
            });

            console.log('📡 Response status:', response.status);
            console.log('📡 Response OK:', response.ok);

            return await this.handleResponse(response);
        } catch (error) {
            console.error('❌ Network error during registration:', error);
            throw new Error(`Network error: ${error.message}`);
        }
    }

    async logout() {
        this.token = null;
        this.user = null;
        localStorage.removeItem('oceanGuardToken');
        localStorage.removeItem('oceanGuardUser');
    }

    // User methods
    async getCurrentUser() {
        const response = await fetch(`${this.baseURL}/users/me`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async updateUser(userData) {
        const response = await fetch(`${this.baseURL}/users/me`, {
            method: 'PUT',
            headers: this.getHeaders(),
            body: JSON.stringify(userData)
        });

        return await this.handleResponse(response);
    }

    // Incident methods
    async createIncident(incidentData) {
        const response = await fetch(`${this.baseURL}/incidents/`, {
            method: 'POST',
            headers: this.getHeaders(),
            body: JSON.stringify(incidentData)
        });

        return await this.handleResponse(response);
    }

    async getMyReports(filters = {}) {
        const params = new URLSearchParams();
        
        Object.keys(filters).forEach(key => {
            if (filters[key] !== null && filters[key] !== undefined) {
                params.append(key, filters[key]);
            }
        });

        // Use incidents endpoint which already filters by user role for PUBLIC users
        const response = await fetch(`${this.baseURL}/incidents/?${params}`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async getIncidents(filters = {}) {
        const params = new URLSearchParams();
        
        Object.keys(filters).forEach(key => {
            if (filters[key] !== null && filters[key] !== undefined) {
                params.append(key, filters[key]);
            }
        });

        // Backend handles role-based filtering automatically
        const response = await fetch(`${this.baseURL}/incidents/?${params}`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async getIncident(incidentId) {
        const response = await fetch(`${this.baseURL}/incidents/${incidentId}`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async verifyIncident(incidentId) {
        const response = await fetch(`${this.baseURL}/incidents/${incidentId}/verify`, {
            method: 'PUT',
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async deployResponse(incidentId) {
        const response = await fetch(`${this.baseURL}/incidents/${incidentId}/deploy`, {
            method: 'PUT',
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async resolveIncident(incidentId) {
        const response = await fetch(`${this.baseURL}/incidents/${incidentId}/resolve`, {
            method: 'PUT',
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    // User management methods
    async getUsers() {
        const response = await fetch(`${this.baseURL}/users/`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async createUser(userData) {
        const response = await fetch(`${this.baseURL}/auth/register`, {
            method: 'POST',
            headers: this.getHeaders(),
            body: JSON.stringify(userData)
        });

        return await this.handleResponse(response);
    }

    async deleteUser(userId) {
        const response = await fetch(`${this.baseURL}/users/${userId}`, {
            method: 'DELETE',
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    // Analytics methods
    async getDashboardAnalytics() {
        const response = await fetch(`${this.baseURL}/analytics/dashboard`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async getIncidentsTimeline(days = 30) {
        const response = await fetch(`${this.baseURL}/analytics/incidents/timeline?days=${days}`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async getIncidentsDistribution() {
        const response = await fetch(`${this.baseURL}/analytics/incidents/distribution`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async getGeographicAnalytics() {
        const response = await fetch(`${this.baseURL}/analytics/geographic`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    // WebSocket connection for real-time updates
    connectWebSocket() {
        if (!this.token) {
            console.warn('No authentication token available for WebSocket connection');
            return null;
        }

        // Use the same host and port as the API baseURL but with WebSocket protocol
        const apiUrl = new URL(this.baseURL);
        const protocol = apiUrl.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${apiUrl.host}/api/ws/incidents`;
        
        console.log('Connecting to WebSocket:', wsUrl);
        const ws = new WebSocket(wsUrl);
        
        ws.onopen = () => {
            console.log('WebSocket connected');
            // Send authentication token
            ws.send(JSON.stringify({
                type: 'auth',
                token: this.token
            }));
        };

        ws.onmessage = (event) => {
            const data = JSON.parse(event.data);
            this.handleWebSocketMessage(data);
        };

        ws.onclose = () => {
            console.log('WebSocket disconnected');
        };

        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        return ws;
    }

    handleWebSocketMessage(data) {
        // Handle different types of WebSocket messages
        switch (data.type) {
            case 'new_incident':
                this.handleNewIncident(data.data);
                break;
            case 'incident_update':
                this.handleIncidentUpdate(data.data);
                break;
            case 'status_update':
                this.handleStatusUpdate(data.data);
                break;
            default:
                console.log('Unknown WebSocket message type:', data.type);
        }
    }

    handleNewIncident(incidentData) {
        // Show notification for new incidents (admin/authority only)
        if (this.user && ['admin', 'authority'].includes(this.user.role)) {
            this.showNotification('New Incident Reported', `Incident ${incidentData.reference_id} reported`, 'warning');
        }
    }

    handleIncidentUpdate(incidentData) {
        // Update incident in UI if displayed
        console.log('Incident updated:', incidentData);
    }

    handleStatusUpdate(incidentData) {
        // Show notification for status updates
        this.showNotification('Incident Status Updated', `Incident ${incidentData.reference_id} status changed to ${incidentData.status}`, 'info');
    }

    showNotification(title, message, type = 'info') {
        // Create and show notification
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <h4>${title}</h4>
                <p>${message}</p>
                <button onclick="this.parentElement.parentElement.remove()">Close</button>
            </div>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }
    
    // Test WebSocket connection (for debugging)
    testWebSocket() {
        console.log('🧪 Testing WebSocket connection...');
        console.log('🔗 Base URL:', this.baseURL);
        
        const apiUrl = new URL(this.baseURL);
        const protocol = apiUrl.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${apiUrl.host}/api/ws/incidents`;
        
        console.log('🔌 WebSocket URL:', wsUrl);
        
        const testWs = new WebSocket(wsUrl);
        
        testWs.onopen = () => {
            console.log('✅ WebSocket connected successfully!');
            
            // Send a test ping message
            testWs.send(JSON.stringify({
                type: 'ping',
                timestamp: new Date().toISOString()
            }));
            
            // Send authentication if token is available
            if (this.token) {
                testWs.send(JSON.stringify({
                    type: 'auth',
                    token: this.token
                }));
            }
            
            // Close after 5 seconds
            setTimeout(() => {
                console.log('🔚 Closing test WebSocket connection');
                testWs.close();
            }, 5000);
        };
        
        testWs.onmessage = (event) => {
            console.log('📨 WebSocket message received:', JSON.parse(event.data));
        };
        
        testWs.onclose = (event) => {
            console.log('🔌 WebSocket closed:', event.code, event.reason);
        };
        
        testWs.onerror = (error) => {
            console.error('❌ WebSocket error:', error);
        };
        
        return testWs;
    }

    // Admin-only methods for rescue teams and authorities
    async getRescueTeams() {
        if (!this.user || this.user.role !== 'admin') {
            throw new Error('Access denied: Admin privileges required');
        }

        const response = await fetch(`${this.baseURL}/admin/teams/`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async addRescueTeam(teamData) {
        if (!this.user || this.user.role !== 'admin') {
            throw new Error('Access denied: Admin privileges required');
        }

        const response = await fetch(`${this.baseURL}/admin/teams/`, {
            method: 'POST',
            headers: this.getHeaders(),
            body: JSON.stringify(teamData)
        });

        return await this.handleResponse(response);
    }

    async getAuthorities() {
        if (!this.user || this.user.role !== 'admin') {
            throw new Error('Access denied: Admin privileges required');
        }

        const response = await fetch(`${this.baseURL}/admin/authorities/`, {
            headers: this.getHeaders()
        });

        return await this.handleResponse(response);
    }

    async addAuthority(authorityData) {
        if (!this.user || this.user.role !== 'admin') {
            throw new Error('Access denied: Admin privileges required');
        }

        const response = await fetch(`${this.baseURL}/admin/authorities/`, {
            method: 'POST',
            headers: this.getHeaders(),
            body: JSON.stringify(authorityData)
        });

        return await this.handleResponse(response);
    }

    // Check if current user is admin
    isAdmin() {
        return this.user && this.user.role === 'admin';
    }
}

// Create global API instance
window.oceanHazardAPI = new OceanHazardAPI();

