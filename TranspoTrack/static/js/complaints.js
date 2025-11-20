document.addEventListener('DOMContentLoaded', () => {
    loadComplaints();
});

async function loadComplaints() {
    showLoading('complaintsBody');
    const result = await apiCall('/api/complaints');
    
    if (result.success && result.data) {
        const tbody = document.getElementById('complaintsBody');
        if (result.data.length === 0) {
            showNoData('complaintsBody', 'No complaints found');
            return;
        }
        tbody.innerHTML = result.data.map(c => `
            <tr>
                <td>${c.ComplaintID}</td>
                <td>${c.ComplaintCode}</td>
                <td>${c.PassengerName}</td>
                <td>${c.Title}</td>
                <td><span class="badge badge-info">${c.Category}</span></td>
                <td><span class="badge badge-${getPriorityClass(c.Priority)}">${c.Priority}</span></td>
                <td>${getStatusBadge(c.Status)}</td>
                <td>${formatDate(c.Timestamp)}</td>
                <td>
                    <button class="btn btn-sm btn-success" onclick="openResolveModal(${c.ComplaintID})" title="Resolve">
                        <i class="fas fa-check"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    } else {
        showError('complaintsBody', result.error || 'Failed to load complaints');
    }
}

function getPriorityClass(priority) {
    const classes = {
        'Low': 'info',
        'Medium': 'warning',
        'High': 'danger',
        'Critical': 'danger'
    };
    return classes[priority] || 'primary';
}

function filterComplaints() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const rows = document.querySelectorAll('#complaintsBody tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function filterByStatus(status) {
    const rows = document.querySelectorAll('#complaintsBody tr');
    rows.forEach(row => {
        if (status === 'all') {
            row.style.display = '';
        } else {
            const statusCell = row.cells[6]; // Status column
            const text = statusCell ? statusCell.textContent : '';
            row.style.display = text.includes(status) ? '' : 'none';
        }
    });
}

function openResolveModal(id) {
    document.getElementById('complaintId').value = id;
    document.getElementById('resolveModal').classList.add('active');
}

async function resolveComplaint(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const id = formData.get('complaintId');
    const data = {
        status: formData.get('status'),
        resolution: formData.get('resolution')
    };
    
    const result = await apiCall(`/api/complaints/${id}/status`, 'PUT', data);
    
    if (result.success) {
        showToast('Complaint updated successfully', 'success');
        closeResolveModal();
        loadComplaints();
    } else {
        showToast('Error: ' + (result.error || 'Update failed'), 'danger');
    }
}

function closeResolveModal() {
    document.getElementById('resolveModal').classList.remove('active');
}

window.onclick = function(event) {
    const modal = document.getElementById('resolveModal');
    if (event.target === modal) closeResolveModal();
}
