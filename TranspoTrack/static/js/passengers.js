// Load passengers on page load
document.addEventListener('DOMContentLoaded', () => {
    loadPassengers();
});

// Load all passengers
async function loadPassengers() {
    showLoading('passengersBody');
    const result = await apiCall('/api/passengers');
    
    if (result.success && result.data) {
        displayPassengers(result.data);
    } else {
        showError('passengersBody', result.error || 'Failed to load passengers');
    }
}

// Display passengers in table
function displayPassengers(passengers) {
    const tbody = document.getElementById('passengersBody');
    
    if (passengers.length === 0) {
        showNoData('passengersBody', 'No passengers found');
        return;
    }
    
    tbody.innerHTML = passengers.map(p => `
        <tr>
            <td>${p.PassengerID}</td>
            <td>${p.FirstName} ${p.LastName}</td>
            <td>${p.Email}</td>
            <td>${p.PhoneNumbers || 'N/A'}</td>
            <td>${formatDate(p.DateOfBirth)}</td>
            <td>${p.City || 'N/A'}</td>
            <td>${getStatusBadge(p.Status)}</td>
            <td>${createActionButtons(p.PassengerID, 'editPassenger', 'deletePassenger')}</td>
        </tr>
    `).join('');
}

// Filter passengers
function filterPassengers() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const rows = document.querySelectorAll('#passengersBody tr');
    
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

// Open add modal
function openAddModal() {
    document.getElementById('modalTitle').innerHTML = '<i class="fas fa-user-plus"></i> Add Passenger';
    document.getElementById('passengerForm').reset();
    document.getElementById('passengerId').value = '';
    document.getElementById('passengerModal').classList.add('active');
}

// Edit passenger
async function editPassenger(id) {
    const result = await apiCall(`/api/passengers/${id}`);
    
    if (result.success && result.data.length > 0) {
        const passenger = result.data[0];
        document.getElementById('modalTitle').innerHTML = '<i class="fas fa-user-edit"></i> Edit Passenger';
        document.getElementById('passengerId').value = passenger.PassengerID;
        document.getElementById('firstName').value = passenger.FirstName;
        document.getElementById('lastName').value = passenger.LastName;
        document.getElementById('email').value = passenger.Email;
        document.getElementById('dateOfBirth').value = passenger.DateOfBirth;
        document.getElementById('city').value = passenger.City || '';
        document.getElementById('address').value = passenger.Address || '';
        document.getElementById('status').value = passenger.Status;
        document.getElementById('passengerModal').classList.add('active');
    }
}

// Save passenger
async function savePassenger(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const data = {
        firstName: formData.get('firstName'),
        lastName: formData.get('lastName'),
        email: formData.get('email'),
        phone: formData.get('phone'),
        dateOfBirth: formData.get('dateOfBirth'),
        city: formData.get('city'),
        address: formData.get('address'),
        status: formData.get('status')
    };
    
    const id = formData.get('passengerId');
    const url = id ? `/api/passengers/${id}` : '/api/passengers';
    const method = id ? 'PUT' : 'POST';
    
    const result = await apiCall(url, method, data);
    
    if (result.success) {
        showToast(id ? 'Passenger updated successfully' : 'Passenger added successfully', 'success');
        closeModal();
        loadPassengers();
    } else {
        showToast('Error: ' + (result.error || 'Operation failed'), 'danger');
    }
}

// Delete passenger
async function deletePassenger(id) {
    if (!confirmDelete('Are you sure you want to delete this passenger?')) {
        return;
    }
    
    const result = await apiCall(`/api/passengers/${id}`, 'DELETE');
    
    if (result.success) {
        showToast('Passenger deleted successfully', 'success');
        loadPassengers();
    } else {
        showToast('Error: ' + (result.error || 'Delete failed'), 'danger');
    }
}

// Close modal
function closeModal() {
    document.getElementById('passengerModal').classList.remove('active');
}

// Close modal on outside click
window.onclick = function(event) {
    const modal = document.getElementById('passengerModal');
    if (event.target === modal) {
        closeModal();
    }
}
