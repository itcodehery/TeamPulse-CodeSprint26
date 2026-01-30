# Application Logic & Implementation Flow

## Core Concept
The application connects three entities to redistribute surplus food:
1.  **Donors** (Users): Entities with extra food (Caterers, Event Organizers, Individuals).
2.  **Organizations** (NGOs): Entities requesting food to feed the needy.
3.  **Riders**: Logistics partners who transport the food.

## The Workflow
1.  **Request**: An Organization posts a request for food (e.g., "Feeding 50 people").
2.  **Discovery**: A Donor views the map and sees open requests.
3.  **Donation**: The Donor selects a specific organization's request and confirms they want to donate their extra food to fulfill it.
4.  **Assignment**: The system assigns a nearby Rider to the transaction.
5.  **Transit**: The Rider picks up the food from the Donor and updates status to `in-transit`.
6.  **Completion**: The Rider delivers food to the Organization and marks the order as `completed`.

---

## Implementation Plan

### Phase 1: Organization - Request Creation
*   **Goal**: Allow NGOs to broadcast their needs.
-   [ ] **UI**: Create "New Request" Screen for Organization users.
-   [ ] **Backend**: Insert row into `food_requests` table with:
    -   `org_id`: ID of the organization.
    -   `quantity`: Number of people/meals needed.
    -   `food_type`: Type of food requested (optional preference).
    -   `status`: 'open'.
    -   `location`: Inherited from Organization's profile.

### Phase 2: Donor - Discovery & Donation (Frontend In-Progress)
*   **Goal**: Enable Donors to find and fulfill requests.
-   [x] **Map Interface**: Display active requests (`status='open'`) as markers on the map.
-   [x] **List Interface**: Sort requests to show "Open" needs first.
-   [ ] **Donation Action**:
    -   When Donor clicks "Donate & Fulfill":
    -   Update `food_requests` row:
        -   `donor_id`: Current User ID.
        -   `status`: 'pending_pickup'.
    -   Trigger Rider Assignment.

### Phase 3: Automated Rider Assignment (Backend)
*   **Goal**: seamless logistics assignment.
-   [ ] **Triggers**:
    -   Listen for update on `food_requests` where `status` changes to `pending_pickup`.
-   [ ] **Logic**:
    -   Query `rider_profiles` for riders where `is_available = true` within X km radius.
    -   Select nearest rider.
    -   Update `food_requests` row with `rider_id`.
    -   Push Notification to Rider.
    -   Push Notification to Donor ("Rider [Name] is on the way").

### Phase 4: Rider - Delivery Workflow
*   **Goal**: Execute the transport.
-   [ ] **Rider Dashboard**:
    -   Show "Active Job" if a request is assigned.
    -   Show Pickup (Donor) and Drop-off (Organization) details.
-   [ ] **Actions**:
    -   **"Picked Up"**: Updates status to `in_transit`.
    -   **"Delivered"**: Updates status to `completed`.
-   [ ] **History**: Log completed deliveries in Rider profile.

### Phase 5: History & Analytics
-   [ ] **Donor History**: "Your Contributions" tab shows fulfilled requests (Implemented).
-   [ ] **Organization History**: Show received donations.
-   [ ] **Impact Score**: Calculate total meals saved/people fed.
