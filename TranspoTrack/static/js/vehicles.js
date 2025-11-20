document.addEventListener('DOMContentLoaded', () => {
    loadVehicles();
});

async function loadVehicles() {
    showLoading('vehiclesBody');
    const result = await apiCall('/api/vehicles');
    
    if (result.success && result.data) {
        const tbody = document.getElementById('vehiclesBody');
        if (result.data.length === 0) {
            showNoData('vehiclesBody', 'No vehicles found');
            return;
        }
        tbody.innerHTML = result.data.map(v => `
            <tr>
                <td>${v.VehicleID}</td>
                <td>${v.VehicleNumber}</td>
                <td><span class="badge badge-primary">${v.Type}</span></td>
                <td>${v.Model || 'N/A'}</td>
                <td>${v.Capacity}</td>
                <td>${v.RegistrationNumber}</td>
                <td><span class="badge badge-info">${v.FuelType}</span></td>
                <td>${getStatusBadge(v.Status)}</td>
                <td>${createActionButtons(v.VehicleID, 'editVehicle', 'deleteVehicle')}</td>
            </tr>
        `).join('');
    } else {
        showError('vehiclesBody', result.error || 'Failed to load vehicles');
    }
}

function filterVehicles() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const rows = document.querySelectorAll('#vehiclesBody tr');
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function openAddModal() {
    document.getElementById('modalTitle').innerHTML = '<i class="fas fa-bus"></i> Add Vehicle';
    document.getElementById('vehicleForm').reset();
    document.getElementById('vehicleId').value = '';
    document.getElementById('vehicleModal').classList.add('active');
}

async function editVehicle(id) {
    const result = await apiCall(`/api/vehicles/${id}`);
    if (result.success && result.data.length > 0) {
        const vehicle = result.data[0];
        document.getElementById('modalTitle').innerHTML = '<i class="fas fa-bus"></i> Edit Vehicle';
        document.getElementById('vehicleId').value = vehicle.VehicleID;
        document.getElementById('vehicleNumber').value = vehicle.VehicleNumber;
        document.getElementById('type').value = vehicle.Type;
        document.getElementById('model').value = vehicle.Model || '';
        document.getElementById('capacity').value = vehicle.Capacity;
        document.getElementById('registrationNumber').value = vehicle.RegistrationNumber;
        document.getElementById('fuelType').value = vehicle.FuelType;
        document.getElementById('status').value = vehicle.Status;
        document.getElementById('vehicleModal').classList.add('active');
    }
}

async function saveVehicle(event) {
    event.preventDefault();
    const formData = new FormData(event.target);
    const data = {
        vehicleNumber: formData.get('vehicleNumber'),
        type: formData.get('type'),
        model: formData.get('model'),
        capacity: formData.get('capacity'),
        registrationNumber: formData.get('registrationNumber'),
        fuelType: formData.get('fuelType'),
        status: formData.get('status')
    };
    
    const id = formData.get('vehicleId');
    const url = id ? `/api/vehicles/${id}` : '/api/vehicles';
    const method = id ? 'PUT' : 'POST';
    
    const result = await apiCall(url, method, data);
    
    if (result.success) {
        showToast(id ? 'Vehicle updated successfully' : 'Vehicle added successfully', 'success');
        closeModal();
        loadVehicles();
    } else {
        showToast('Error: ' + (result.error || 'Operation failed'), 'danger');
    }
}

async function deleteVehicle(id) {
    if (!confirmDelete('Are you sure you want to delete this vehicle?')) return;
    const result = await apiCall(`/api/vehicles/${id}`, 'DELETE');
    if (result.success) {
        showToast('Vehicle deleted successfully', 'success');
        loadVehicles();
    } else {
        showToast('Error: ' + (result.error || 'Delete failed'), 'danger');
    }
}

function closeModal() {
    document.getElementById('vehicleModal').classList.remove('active');
}

window.onclick = function(event) {
    const modal = document.getElementById('vehicleModal');
    if (event.target === modal) closeModal();
}
