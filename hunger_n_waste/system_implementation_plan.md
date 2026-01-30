# System Implementation Plan: Hunger n Waste Redistribution

This document outlines the step-by-step plan to implement the core food redistribution workflow involving Organizations, Donors, and Riders.

## 1. Database Schema Design (Supabase)

We need a table to track food requests and their lifecycle.

### Table: `food_requests`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key |
| `org_id` | `uuid` | Foreign Key to `organization_profiles.id` |
| `food_type` | `text` | Short description (e.g., "Veg Meals") |
| `quantity` | `int` | Number of people/servings needed |
| `status` | `enum` | `open`, `pending_pickup`, `in_transit`, `completed`, `cancelled` |
| `donor_id` | `uuid` | Foreign Key to `donor_profiles.id` (Nullable, filled when locked) |
| `rider_id` | `uuid` | Foreign Key to `rider_profiles.id` (Nullable, filled when assigned) |
| `location` | `geography` | Lat/Long from Organization profile (cached for easier querying) |
| `created_at` | `timestamp` | Creation time |
| `updated_at` | `timestamp` | Last update time |

## 2. Organization Portal: Create Request

**Goal**: Allow organizations to post a need.

1.  **UI**: Create `OrganizationHomeScreen`.
    *   Display list of active/past requests.
    *   Add "New Request" Floating Action Button (FAB).
2.  **Feature**: "New Request" Dialog/Screen.
    *   Input: `Food Type` (optional/dropdown), `Quantity` (Slider or Number Input, e.g., "For 20 people").
    *   Action: `Submit` button inserts row into `food_requests` with status `open`.

## 3. Donor Portal: Map & Discovery

**Goal**: Donors see needs on the map and choose one to fulfill.

1.  **UI**: Update active `HomeScreen` (for Donors).
    *   Load `flutter_map` (already set up).
2.  **Logic**: Fetch `open` requests from Supabase.
    *   Use Supabase Realtime or periodic refetch to keep map updated.
3.  **Visualization**: Custom Map Markers.
    *   Show Organization Pin.
    *   **Overlay/Badge**: Show the `quantity` (e.g., "20") on the pin.
    *   Clicking a pin opens a `RequestDetailsBottomSheet`.
4.  **Interaction**: `RequestDetailsBottomSheet`.
    *   Show Org Name, Address, and Demand ("Need food for 20 people").
    *   Action: `Donate & Fulfill` button.

## 4. Transaction Logic: Locking the Request

**Goal**: When a donor accepts, lock the request so no one else can take it.

1.  **Logic**: On `Donate & Fulfill` press:
    *   Call a Supabase RPC or generic update to set:
        *   `status` = `pending_pickup`
        *   `donor_id` = `current_user.id`
    *   **Constraint**: Ensure status was `open` before updating (optimistic locking).
2.  **UI Feedback**:
    *   Show success message: "Thank you! Finding a rider..."
    *   Disable/Hide the request from the map for other users.
    *   Show "Active Donation" card on Donor's home screen.

## 5. Rider Assignment System

**Goal**: Find the nearest rider and assign the job.

1.  **Logic (Simple Geo-Query)**:
    *   Triggered immediately after Donor locks the request (can be done client-side by Donor app or via Supabase Edge Function).
    *   Query `rider_profiles`:
        *   Where `is_available` = `true`.
        *   Order by distance to `donor_location` (or Org location, depending on flow. Usually Donor -> Org, so find rider near Donor).
    *   **Assignment**:
        *   Update `food_requests` row: set `rider_id` = `closest_rider.id`.
        *   (Optional) Update `rider_profile`: set `is_available` = `false` or `current_job` = `request_id`.
2.  **Rider UI**:
    *   If Rider App is open, listen to changes on `food_requests` where `rider_id` == `me`.
    *   Show "New Delivery Job" alert.
    *   Route: Donor Location -> Organization Location.

## 6. Implementation Stages

### Phase A: Organization - Posting Requests (CRUD)
- [ ] Create `food_requests` table in Supabase.
- [ ] Implement `OrganizationDashboard`.
- [ ] Implement `AddRequestFunctionality`.

### Phase B: Donor - Viewing & Accepting
- [ ] Implement `DonorMapScreen` fetching live data.
- [ ] Create Custom Markers with demand indicators.
- [ ] Implement `AcceptRequest` logic (Database Update).

### Phase C: Rider - Assignment & Routing
- [ ] Implement simplistic "Find Nearest Rider" algorithm.
- [ ] Implement `RiderDashboard` to see assigned job.
