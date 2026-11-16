# Razzil

Copy [Subscription.swift](Subscription.swift) into your app target for a Boolean backed by verified StoreKit 2 subscription entitlements.

## Check subscription access

Use a group ID when every plan in the group grants access. Use product IDs when you need to select specific plans, including legacy plans you still honor.

```swift
let subscription = Subscription(groupID: "your.subscription.group.id")
// Or use Subscription(productIDs: ["monthly.product.id", "yearly.product.id"]).
let isSubscribed = await subscription.isSubscribed
```

Read the Boolean at launch and after a verified purchase or restore. It includes billing grace periods and eligible App Store Family Sharing. The app owns its paywall, purchase completion handling, and any shared profile access rules.

## Observe transaction updates

Start one listener per subscription scope at app launch. Apply the refreshed Boolean in the callback so Razzil can finish the transaction after the callback returns.

```swift
let updatesTask = Task {
    await subscription.observeUpdates { isSubscribed in
        await appStore.updateSubscriptionStatus(isSubscribed)
    }
}
```

Cancel the task when its owner is done listening. Use your paywall's purchase completion handler to update access immediately for purchases completed there.

## License

MIT. The full license is included in the Swift file so it travels with the code.
