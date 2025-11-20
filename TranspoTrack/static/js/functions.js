async function calculateAge(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const passengerId = formData.get('passengerId');
    
    const result = await apiCall(`/api/passenger-age/${passengerId}`);
    
    if (result.success && result.data && result.data.length > 0) {
        const age = result.data[0].age;
        const resultDiv = document.getElementById('ageResult');
        
        if (age !== null) {
            resultDiv.innerHTML = `
                <div class="function-result-success">
                    <h4><i class="fas fa-check-circle"></i> Age Calculated</h4>
                    <p>Passenger ID: <strong>${passengerId}</strong></p>
                    <p>Age: <strong>${age} years</strong></p>
                </div>
            `;
        } else {
            resultDiv.innerHTML = `
                <div class="function-result-error">
                    <h4><i class="fas fa-exclamation-circle"></i> Passenger Not Found</h4>
                    <p>No passenger found with ID: ${passengerId}</p>
                </div>
            `;
        }
        resultDiv.style.display = 'block';
    } else {
        showToast('Error calculating age', 'danger');
    }
}

async function checkSeat(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const data = {
        scheduleId: formData.get('scheduleId'),
        journeyDate: formData.get('journeyDate'),
        seatNumber: formData.get('seatNumber')
    };
    
    const result = await apiCall('/api/check-seat', 'POST', data);
    
    if (result.success && result.data && result.data.length > 0) {
        const status = result.data[0].status;
        const resultDiv = document.getElementById('seatResult');
        
        if (status === 'AVAILABLE') {
            resultDiv.innerHTML = `
                <div class="function-result-success">
                    <h4><i class="fas fa-check-circle"></i> Seat Available</h4>
                    <p>Schedule ID: <strong>${data.scheduleId}</strong></p>
                    <p>Journey Date: <strong>${formatDate(data.journeyDate)}</strong></p>
                    <p>Seat: <strong>${data.seatNumber}</strong></p>
                    <p class="text-success"><i class="fas fa-check"></i> This seat is available for booking!</p>
                </div>
            `;
        } else {
            resultDiv.innerHTML = `
                <div class="function-result-error">
                    <h4><i class="fas fa-times-circle"></i> Seat Not Available</h4>
                    <p>Schedule ID: <strong>${data.scheduleId}</strong></p>
                    <p>Journey Date: <strong>${formatDate(data.journeyDate)}</strong></p>
                    <p>Seat: <strong>${data.seatNumber}</strong></p>
                    <p class="text-danger"><i class="fas fa-times"></i> This seat is already booked!</p>
                </div>
            `;
        }
        resultDiv.style.display = 'block';
    } else {
        showToast('Error checking seat availability', 'danger');
    }
}

async function testAge(passengerId) {
    const result = await apiCall(`/api/passenger-age/${passengerId}`);
    
    if (result.success && result.data && result.data.length > 0) {
        const age = result.data[0].age;
        showToast(`Passenger ${passengerId}: ${age} years old`, 'success');
    }
}

async function testSeat(scheduleId, journeyDate, seatNumber) {
    const data = { scheduleId, journeyDate, seatNumber };
    const result = await apiCall('/api/check-seat', 'POST', data);
    
    if (result.success && result.data && result.data.length > 0) {
        const status = result.data[0].status;
        const message = `Seat ${seatNumber}: ${status}`;
        const type = status === 'AVAILABLE' ? 'success' : 'warning';
        showToast(message, type);
    }
}

async function runCombinedTest() {
    const resultDiv = document.getElementById('combinedResult');
    resultDiv.innerHTML = '<div class="loading-spinner"></div><p>Running tests...</p>';
    resultDiv.style.display = 'block';
    
    // Test multiple passengers
    const tests = [];
    for (let i = 1; i <= 5; i++) {
        tests.push(apiCall(`/api/passenger-age/${i}`));
    }
    
    const results = await Promise.all(tests);
    
    let html = '<div class="combined-test-results"><h3>Combined Test Results</h3><table class="data-table"><thead><tr><th>Passenger ID</th><th>Age</th><th>Status</th></tr></thead><tbody>';
    
    results.forEach((result, index) => {
        const passengerId = index + 1;
        if (result.success && result.data && result.data.length > 0) {
            const age = result.data[0].age;
            html += `<tr><td>${passengerId}</td><td>${age || 'N/A'}</td><td><span class="badge badge-success">Success</span></td></tr>`;
        } else {
            html += `<tr><td>${passengerId}</td><td>-</td><td><span class="badge badge-danger">Error</span></td></tr>`;
        }
    });
    
    html += '</tbody></table></div>';
    resultDiv.innerHTML = html;
}
