# Request to the identity team

The identity team owns Entra, so they create the groups. We manage everything after that.

| Task | Who |
|---|---|
| Create the groups | Identity team |
| Decide who goes in each group | Platform team + DNA lead |
| Add and remove members day to day | Platform team, as group owners |
| Give groups permissions in Azure | Platform team (the templates do it) |
| Give groups access to Fabric workspaces | Platform team, as workspace admin |

## Email or ticket to send

```text
Hi team,

We're setting up the ML platform for the DNA team and need the following
Entra SECURITY groups (not Microsoft 365 groups), with assigned membership:

  sg-dna-platform-admins
  sg-dna-data-engineers
  sg-dna-data-scientists
  sg-dna-ml-engineers
  sg-dna-genai-developers
  sg-dna-viewers

Please set <your name> and <DNA lead name> as OWNERS of these groups so
we can manage membership without raising tickets.

If these names don't fit your naming convention, please adjust them and
send us the final names and their object IDs.

These groups are only for Azure role assignments and Fabric workspace
access. They don't need any Entra admin roles.

Thanks!
```

## Also ask them

- **What's your naming convention?** If they rename the groups, update the names in `scripts/config.sh`.
- **Do you use PIM** for admin groups? If yes, you may need to activate your `sg-dna-platform-admins` membership before deploying.

## If they won't make us owners

Every new joiner then waits for an identity-team ticket. Agree a turnaround (for example, same day) and add it to the [request menu](request-menu.md).

## No identity-team request needed for

- **The CI/CD identity.** The templates create a user-assigned managed identity with a GitHub OIDC federated credential, so no service principal or app registration is needed.
- **Managed identities** for the Azure ML workspace, Foundry and apps. Azure creates these automatically.
