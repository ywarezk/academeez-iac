# Jenkins agent

I'm wondering if maybe I should use the same jenkins master.  
And just use a new agent.  

Could save me time cause everything is already configured and we have a ready jenkins which I like.

Think it's best to start with just a jenkins agent.

## What included

- new project
- gce instance to run jenkins agent with ssh agent using the provided public key
- service account for the jenkins agent
- bucket
- the jenkins service account cat impresionate the terraform
- adds NAT

