# Promotion checklist

A model or pipeline moves from the sandbox to production only when every box is ticked.

- [ ] The code is in Git and is deployed by CI/CD, not by hand.
- [ ] It passed its agreed quality test (for example, a minimum F1 score), and the result is recorded.
- [ ] The data it uses is labelled and approved for that use.
- [ ] It runs as a robot identity (managed identity), not a person's account.
- [ ] Alerts are on and a named person owns it.
- [ ] The production environment uses private networking (see [network decision](network-decision.md)).
- [ ] The business owner has signed off.
- [ ] Security has signed off.

## Sandbox test run

Do this after the first deployment, before telling the DNA team the platform is ready:

1. Create a test user and add them to `sg-dna-data-scientists`.
2. As the test user:
   - open a Fabric notebook and read the landed data,
   - start a small compute instance in Azure ML,
   - upload a file in Azure ML studio,
   - chat with the approved model in the Foundry project.
3. Try things that should be blocked:
   - deploy a new model in Foundry (should be refused),
   - call the Foundry model with an API key instead of an Entra login (should fail),
   - open Azure ML from an account that isn't in any `sg-dna-*` group (should be refused).
4. Check that a test alert reaches the platform team.
5. Delete the test user. Write down anything that went wrong and fix the templates.
