// Similar structure to passengers.js
document.addEventListener('DOMContentLoaded', () => {
    loadStations();
});

async function loadStations() {
    showLoading('stationsBody');
    const result = await apiCall('/api/stations');
    
    if (result.success && result.data) {
        const tbody = document.getElementById('stationsBody');
        if (result.data.length === 0) {
            showNoData('stationsBody', 'No stations found');
            return;
        }
        tbody.innerHTML = result.data.map(s => `
            <tr>
                <td>${s.StationID}</td>
                <td>${s.StationCode}</td>
                <td>${s.Name}</td>
                <td>${s.Location}</td>
                <td><span class="badge badge-info">${s.Type}</span></td>
                <td>${s.Zone || 'N/A'}</td>
                <td>${getStatusBadge(s.Status)}</td>
                <td>${createActionButtons(s.StationID, 'editStation', 'deleteStation')}</td>
            </tr>
        `).join('');
    } else {
        showError('stationsBody', result.error || 'Failed to load stations');
    }
}

function filterStations() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const rows = document.querySelectorAll('#stationsBody tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function openAddModal() {
    document.getElementById('modalTitle').innerHTML = '<i class="fas fa-location-dot"></i> Add Station';
    document.getElementById('stationForm').reset();
    document.getElementById('stationId').value = '';
    document.getElementById('stationModal').classList.add('active');
}

async function editStation(id) {
    const result = await apiCall(`/api/stations/${id}`);
    if (result.success && result.data.length > 0) {
        const station = result.data[0];
        document.getElementById('modalTitle').innerHTML = '<i class="fas fa-location-dot"></i> Edit Station';
        document.getElementById('stationId').value = station.StationID;
        document.getElementById('stationCode').value = station.StationCode;
        document.getElementById('name').value = station.Name;
        document.getElementById('location').value = station.Location;
        document.getElementById('type').value = station.Type;
        document.getElementById('capacity').value = station.Capacity;
        document.getElementById('zone').value = station.Zone || '';
        document.getElementById('status').value = station.Status;
        document.getElementById('stationModal').classList.add('active');
    }
}

async function saveStation(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const data = {
        stationCode: formData.get('stationCode'),
        name: formData.get('name'),
        location: formData.get('location'),
        type: formData.get('type'),
        capacity: formData.get('capacity'),
        zone: formData.get('zone'),
        status: formData.get('status')
    };
    
    const id = formData.get('stationId');
    const url = id ? `/api/stations/${id}` : '/api/stations';
    const method = id ? 'PUT' : 'POST';
    
    const result = await apiCall(url, method, data);
    
    if (result.success) {
        showToast(id ? 'Station updated successfully' : 'Station added successfully', 'success');
        closeModal();
        loadStations();
    } else {
        showToast('Error: ' + (result.error || 'Operation failed'), 'danger');
    }
}

async function deleteStation(id) {
    if (!confirmDelete('Are you sure you want to delete this station?')) return;
    const result = await apiCall(`/api/stations/${id}`, 'DELETE');
    if (result.success) {
        showToast('Station deleted successfully', 'success');
        loadStations();
    } else {
        showToast('Error: ' + (result.error || 'Delete failed'), 'danger');
    }
}

function closeModal() {
    document.getElementById('stationModal').classList.remove('active');
}

window.onclick = function(event) {
    const modal = document.getElementById('stationModal');
    if (event.target === modal) closeModal();
}
