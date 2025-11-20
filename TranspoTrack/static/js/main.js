// ==================== UTILITY FUNCTIONS ====================

function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast show ${type}`;
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-IN', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR'
    }).format(amount);
}

// ==================== API CALLS ====================

async function apiCall(url, method = 'GET', data = null) {
    const options = {
        method: method,
        headers: {
            'Content-Type': 'application/json',
        }
    };
    
    if (data) {
        options.body = JSON.stringify(data);
    }
    
    try {
        const response = await fetch(url, options);
        const result = await response.json();
        return result;
    } catch (error) {
        console.error('API Error:', error);
        showToast('Error: ' + error.message, 'danger');
        return { success: false, error: error.message };
    }
}

// ==================== NAVIGATION ====================

document.addEventListener('DOMContentLoaded', function() {
    // Mobile navigation toggle
    const navToggle = document.getElementById('navToggle');
    const navMenu = document.getElementById('navMenu');
    
    if (navToggle) {
        navToggle.addEventListener('click', () => {
            navMenu.classList.toggle('active');
        });
    }

    // Add active class to current nav item
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        if (link.getAttribute('href') === currentPath) {
            link.classList.add('active');
        }
    });
});

// ==================== TABLE UTILITIES ====================

function getStatusBadge(status) {
    const statusClasses = {
        'Active': 'badge-success',
        'Inactive': 'badge-danger',
        'Suspended': 'badge-warning',
        'Operational': 'badge-success',
        'Maintenance': 'badge-warning',
        'Closed': 'badge-danger',
        'Booked': 'badge-success',
        'Cancelled': 'badge-danger',
        'Used': 'badge-info',
        'Expired': 'badge-warning',
        'Pending': 'badge-warning',
        'In Progress': 'badge-info',
        'Resolved': 'badge-success',
        'Rejected': 'badge-danger',
        'Completed': 'badge-success',
        'Failed': 'badge-danger'
    };
    
    const badgeClass = statusClasses[status] || 'badge-primary';
    return `<span class="badge ${badgeClass}">${status}</span>`;
}

function createActionButtons(id, editFunc, deleteFunc) {
    return `
        <button class="btn btn-sm btn-primary" onclick="${editFunc}(${id})" title="Edit">
            <i class="fas fa-edit"></i>
        </button>
        <button class="btn btn-sm btn-danger" onclick="${deleteFunc}(${id})" title="Delete">
            <i class="fas fa-trash"></i>
        </button>
    `;
}

// ==================== EXPORT FUNCTIONS ====================

function exportToPDF() {
    showToast('PDF export functionality - Coming soon!', 'info');
}

function exportToExcel() {
    showToast('Excel export functionality - Coming soon!', 'info');
}

function exportToCSV() {
    showToast('CSV export functionality - Coming soon!', 'info');
}

// ==================== CONFIRMATION DIALOGS ====================

function confirmDelete(message = 'Are you sure you want to delete this item?') {
    return confirm(message);
}

// ==================== LOADING STATE ====================

function showLoading(tableId) {
    const tbody = document.getElementById(tableId);
    if (tbody) {
        tbody.innerHTML = `
            <tr>
                <td colspan="20" class="text-center">
                    <div class="loading-spinner"></div>
                    <p>Loading data...</p>
                </td>
            </tr>
        `;
    }
}

function showNoData(tableId, message = 'No data available') {
    const tbody = document.getElementById(tableId);
    if (tbody) {
        tbody.innerHTML = `
            <tr>
                <td colspan="20" class="text-center">
                    <p>${message}</p>
                </td>
            </tr>
        `;
    }
}

function showError(tableId, message) {
    const tbody = document.getElementById(tableId);
    if (tbody) {
        tbody.innerHTML = `
            <tr>
                <td colspan="20" class="text-center text-danger">
                    <i class="fas fa-exclamation-circle"></i>
                    <p>${message}</p>
                </td>
            </tr>
        `;
    }
}
