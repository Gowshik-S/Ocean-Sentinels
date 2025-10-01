/**
 * Ocean Guard Analytics Dashboard
 * Dynamic data fetching from backend API with Chart.js visualizations
 */

// Global variables for charts
let incidentsTypeChart, incidentsTimelineChart, statusDistributionChart;
let analyticsData = null;

// Initialize analytics when page loads
document.addEventListener('DOMContentLoaded', function() {
    console.log('🌊 Analytics Dashboard Initializing...');
    initializeAnalytics();
});

/**
 * Initialize the analytics dashboard
 */
async function initializeAnalytics() {
    try {
        showLoading();
        await loadAnalytics();
        hideLoading();
        updateLastUpdatedTime();
    } catch (error) {
        console.error('❌ Failed to initialize analytics:', error);
        showError('Failed to load analytics dashboard');
    }
}

/**
 * Load analytics data from API with fallback to mock data
 */
async function loadAnalytics() {
    try {
        console.log('📊 Loading analytics data...');
        
        // Try to fetch real data first
        let dashboardData, timelineData;
        
        try {
            // Attempt to fetch from backend
            const dashboardResponse = await fetch('http://localhost:9000/api/analytics/public/dashboard', {
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (dashboardResponse.ok) {
                dashboardData = await dashboardResponse.json();
                console.log('✅ Real dashboard data loaded:', dashboardData);
                
                // Try timeline data too
                const timelineResponse = await fetch('http://localhost:9000/api/analytics/public/timeline?days=30', {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });
                
                if (timelineResponse.ok) {
                    timelineData = await timelineResponse.json();
                    console.log('✅ Real timeline data loaded:', timelineData);
                }
            }
        } catch (apiError) {
            console.log('⚠️ Backend not available, using mock data:', apiError.message);
        }
        
        // Use mock data as fallback
        if (!dashboardData) {
            console.log('📊 Using mock dashboard data');
            dashboardData = {
                total_incidents: 15,
                active_incidents: 8,
                resolved_incidents: 7,
                incidents_by_type: {
                    "Oil Spill": 5,
                    "Tsunami Warning": 3,
                    "Coastal Erosion": 4,
                    "Marine Pollution": 2,
                    "Weather Alert": 1
                },
                last_updated: new Date().toISOString()
            };
        }
        
        if (!timelineData) {
            console.log('📈 Using mock timeline data');
            timelineData = [];
            // Generate last 7 days of sample data
            for (let i = 6; i >= 0; i--) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                timelineData.push({
                    date: date.toISOString().split('T')[0],
                    count: Math.floor(Math.random() * 5) + 1
                });
            }
        }

        // Store analytics data globally
        analyticsData = {
            dashboard: dashboardData,
            timeline: timelineData
        };

        // Update UI
        updateOverviewCards(dashboardData);
        createCharts(dashboardData, timelineData);
        loadRecentActivity();
        loadIncidentsTable();
        
        showContent();
        
    } catch (error) {
        console.error('❌ Error loading analytics:', error);
        throw error;
    }
}

/**
 * Update overview statistics cards
 */
function updateOverviewCards(data) {
    try {
        document.getElementById('total-incidents').textContent = data.total_incidents || 0;
        document.getElementById('active-incidents').textContent = data.active_incidents || 0;
        document.getElementById('resolved-incidents').textContent = data.resolved_incidents || 0;
        
        // Calculate average response time (mock data for now)
        const avgResponseHours = Math.round((data.resolved_incidents || 0) * 2.5);
        document.getElementById('avg-response-time').textContent = `${avgResponseHours}h`;
        
        console.log('✅ Overview cards updated');
    } catch (error) {
        console.error('❌ Error updating overview cards:', error);
    }
}

/**
 * Create all charts
 */
function createCharts(dashboardData, timelineData) {
    try {
        createIncidentsTypeChart(dashboardData);
        createTimelineChart(timelineData);
        createStatusDistributionChart(dashboardData);
        console.log('✅ All charts created');
    } catch (error) {
        console.error('❌ Error creating charts:', error);
    }
}

/**
 * Create incidents by type chart
 */
function createIncidentsTypeChart(data) {
    const ctx = document.getElementById('incidentsTypeChart');
    if (!ctx) return;
    
    if (incidentsTypeChart) {
        incidentsTypeChart.destroy();
    }

    const incidentTypes = data.incidents_by_type || {};
    const labels = Object.keys(incidentTypes);
    const values = Object.values(incidentTypes);
    
    incidentsTypeChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels.length ? labels : ['No Data'],
            datasets: [{
                data: values.length ? values : [1],
                backgroundColor: [
                    '#FF6384',
                    '#36A2EB', 
                    '#FFCE56',
                    '#4BC0C0',
                    '#9966FF',
                    '#FF9F40'
                ],
                borderWidth: 2,
                borderColor: '#fff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        padding: 20,
                        usePointStyle: true
                    }
                }
            }
        }
    });
}

/**
 * Create timeline chart
 */
function createTimelineChart(timelineData) {
    const ctx = document.getElementById('incidentsTimelineChart');
    if (!ctx) return;
    
    if (incidentsTimelineChart) {
        incidentsTimelineChart.destroy();
    }

    // Process timeline data
    const labels = [];
    const data = [];
    
    if (timelineData && timelineData.length > 0) {
        timelineData.forEach(item => {
            labels.push(new Date(item.date).toLocaleDateString());
            data.push(item.count);
        });
    } else {
        // Default empty data for last 7 days
        for (let i = 6; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            labels.push(date.toLocaleDateString());
            data.push(0);
        }
    }

    incidentsTimelineChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Incidents',
                data: data,
                borderColor: '#007bff',
                backgroundColor: 'rgba(0, 123, 255, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4,
                pointBackgroundColor: '#007bff',
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

/**
 * Create status distribution chart
 */
function createStatusDistributionChart(data) {
    const ctx = document.getElementById('statusDistributionChart');
    if (!ctx) return;
    
    if (statusDistributionChart) {
        statusDistributionChart.destroy();
    }

    const statusData = {
        'Pending': data.active_incidents || 0,
        'Resolved': data.resolved_incidents || 0,
        'Verified': Math.floor((data.resolved_incidents || 0) * 0.8) // Mock verified count
    };

    statusDistributionChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: Object.keys(statusData),
            datasets: [{
                data: Object.values(statusData),
                backgroundColor: [
                    '#ffc107',
                    '#28a745', 
                    '#007bff'
                ],
                borderWidth: 1,
                borderColor: '#fff'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            }
        }
    });
}

/**
 * Load recent activity
 */
async function loadRecentActivity() {
    try {
        const activityContainer = document.getElementById('recent-activity');
        if (!activityContainer) return;
        
        // Mock recent activity data for now
        const activities = [
            {
                type: 'pending',
                text: 'New oil spill reported in Mumbai Harbor',
                time: '5 minutes ago',
                icon: 'fas fa-exclamation-circle'
            },
            {
                type: 'resolved',
                text: 'Tsunami warning system test completed',
                time: '1 hour ago',
                icon: 'fas fa-check-circle'
            },
            {
                type: 'verified',
                text: 'Coastal erosion assessment verified',
                time: '3 hours ago',
                icon: 'fas fa-clipboard-check'
            }
        ];

        activityContainer.innerHTML = activities.map(activity => `
            <div class="activity-item">
                <div class="activity-icon ${activity.type}">
                    <i class="${activity.icon}"></i>
                </div>
                <div class="activity-content">
                    <p class="activity-text">${activity.text}</p>
                    <span class="activity-time">${activity.time}</span>
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('❌ Error loading recent activity:', error);
    }
}

/**
 * Load incidents table
 */
async function loadIncidentsTable() {
    try {
        const tableBody = document.querySelector('#incidents-table tbody');
        if (!tableBody) return;
        
        // Sample incidents data
        const sampleIncidents = [
            {
                reference_id: 'OH-2024-001',
                type: 'Oil Spill',
                location: 'Mumbai Harbor',
                status: 'Pending',
                urgency: 'High',
                created_at: '2024-01-15T10:30:00Z'
            },
            {
                reference_id: 'OH-2024-002', 
                type: 'Tsunami Warning',
                location: 'Chennai Coast',
                status: 'Resolved',
                urgency: 'Critical',
                created_at: '2024-01-14T08:15:00Z'
            }
        ];

        tableBody.innerHTML = sampleIncidents.map(incident => `
            <tr>
                <td>${incident.reference_id}</td>
                <td>${incident.type}</td>
                <td>${incident.location}</td>
                <td><span class="status-badge ${incident.status.toLowerCase()}">${incident.status}</span></td>
                <td><span class="urgency-badge ${incident.urgency.toLowerCase()}">${incident.urgency}</span></td>
                <td>${new Date(incident.created_at).toLocaleDateString()}</td>
                <td>
                    <button class="btn btn--small btn--secondary" onclick="viewIncident('${incident.reference_id}')">
                        View
                    </button>
                </td>
            </tr>
        `).join('');
        
    } catch (error) {
        console.error('❌ Error loading incidents table:', error);
        const tableBody = document.querySelector('#incidents-table tbody');
        if (tableBody) {
            tableBody.innerHTML = '<tr><td colspan="7" class="loading-cell">Error loading incidents</td></tr>';
        }
    }
}

/**
 * UI Helper Functions
 */
function showLoading() {
    const loading = document.getElementById('loading-indicator');
    const content = document.getElementById('analytics-content');
    const error = document.getElementById('error-message');
    
    if (loading) loading.style.display = 'flex';
    if (content) content.style.display = 'none';
    if (error) error.style.display = 'none';
}

function hideLoading() {
    const loading = document.getElementById('loading-indicator');
    if (loading) loading.style.display = 'none';
}

function showContent() {
    const content = document.getElementById('analytics-content');
    const error = document.getElementById('error-message');
    
    if (content) content.style.display = 'block';
    if (error) error.style.display = 'none';
}

function showError(message) {
    const loading = document.getElementById('loading-indicator');
    const content = document.getElementById('analytics-content');
    const error = document.getElementById('error-message');
    const errorText = document.getElementById('error-text');
    
    if (loading) loading.style.display = 'none';
    if (content) content.style.display = 'none';
    if (error) error.style.display = 'flex';
    if (errorText) errorText.textContent = message;
}

function updateLastUpdatedTime() {
    const now = new Date();
    const timeString = now.toLocaleString('en-IN', {
        day: '2-digit',
        month: 'short', 
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: 'Asia/Kolkata'
    });
    
    const lastUpdatedElement = document.getElementById('last-updated');
    if (lastUpdatedElement) {
        lastUpdatedElement.textContent = `Last Updated: ${timeString} IST`;
    }
}

/**
 * Export data functionality
 */
function exportData() {
    try {
        if (!analyticsData) {
            alert('No data available to export');
            return;
        }

        const dataToExport = {
            exportDate: new Date().toISOString(),
            dashboard: analyticsData.dashboard,
            timeline: analyticsData.timeline
        };

        const dataStr = JSON.stringify(dataToExport, null, 2);
        const dataBlob = new Blob([dataStr], {type: 'application/json'});
        
        const url = URL.createObjectURL(dataBlob);
        const downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.download = `ocean-guard-analytics-${new Date().toISOString().split('T')[0]}.json`;
        downloadLink.click();
        
        URL.revokeObjectURL(url);
        
        console.log('✅ Analytics data exported successfully');
    } catch (error) {
        console.error('❌ Error exporting data:', error);
        alert('Failed to export data');
    }
}

/**
 * View incident details
 */
function viewIncident(referenceId) {
    console.log('📋 Viewing incident:', referenceId);
    alert(`Viewing incident: ${referenceId}\n\nThis functionality will be implemented in the next update.`);
}

console.log('🌊 Analytics Dashboard JavaScript Loaded');
