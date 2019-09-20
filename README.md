# FlatMate-API-Swift
The Swift library to communicate with the FlatMate API.
Uses the SwiftJSON library.

## Structure
- session: FMSession
  - user: FMUser
  - flat: FMFlat
    - shopping list: [FMShoppingListItem]
    - payments: [FMPayment]
    - chores: [FMChore]
    - flatmates: [FMUser]
