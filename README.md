# tab-terraform

This will create multiple AWS resources. Here is the `directory` structure:

```
├── README.md
├── services
│   ├── httpd
│   └── nginx
└── platform
    ├── cluster
    ├── rds
    └── alb
```
3 level directory structure

```
.
├── README.md
├── service
│   ├── httpd
│   │   ├── Makefile
│   │   ├── README.md
│   │   ├── _settings.tf
│   │   ├── config.yaml
│   │   └── main.tf
│   └── nginx
│       ├── Makefile
│       ├── README.md
│       ├── _settings.tf
│       ├── config.yaml
│       └── main.tf
└── platform
    ├── cluster
    │   ├── Makefile
    │   ├── README.md
    │   ├── _data.tf
    │   ├── _settings.tf
    │   ├── conf.tfbackend
    │   ├── config.yaml
    │   └── main.tf
    ├── rds
    │   ├── Makefile
    │   ├── README.md
    │   ├── _settings.tf
    │   ├── conf.tfbackend
    │   ├── config.yaml
    │   └── main.tf
    └── alb
        ├── Makefile
        ├── README.md
        ├── _data.tf
        ├── _settings.tf
        ├── config.yaml
        ├── main.tf
        └── output.tf
```

Platform have all resoures which we required for our services 

All the services will be in the Services directory.



# Deployment Steps

1. Deploying Cluster
    - Go to the specified folder:
        ```bash
        cd platform/cluster
        ```

    - Update `config.yaml` with environment block in which you want to deploy the Cluster with Hosts. The contents of `config.yaml` are as follows:
        ```yaml
        workspaces:
         yarra-non-baseline:

        autoscaling_capacity_providers:     
          weight: 60
          base: 20

        autoscaling:
          name: "myasg"
          instance_type: "t3.large"
          image_id:  "ami-0e1ce54e679f83a66"
 
        ```
        Just add a new environment block if you want to create Cluster in that environment. For example: we added `yarra-non-baseline` environment block in the above file.

    - Set the `WORPSPACE` variable.
        ```
        export WORPSPACE=<environment name>
        ```
        The value of WORKSPACE should be same which you defined in the above `config.yaml` file. For example: `export WORPSPACE=yarra-non-baseline`

    - Run the below commands sequentially to deploy the Cluster with Hosts
        ```
        make init
        make plan
        make apply
        ```
        - `make init` will initialise the module as well as will create the `terraform workspace`
        - `make plan` will output the plan in `.terraform-plan-<environment>` file
        - `make apply` will apply the `.terraform-plan-<environment>` file and will create the required resources

2. Deploying  ALB
    - Go to the specified folder:
        ```bash
        cd platform/shared-alb
        ```

    - Update `config.yaml` with environment block in which you want to deploy the Shared ALB. The `config.yaml` for alb is as follows:
        ```yaml
        workspaces:

            # Environment/Workspace names
        yarra-non-baseline:
          aws:   
          local:
            container_port: 80

        ```

    - Set the `WORPSPACE` variable (WORPSPACE = ENVIRONMENT)
        ```
        export WORPSPACE=<environment name>
        ```

    - Run the below commands sequentially to deploy the Cluster with Hosts
        ```
        make init
        make plan
        make apply
        ```
        

## How to Onboard new service

- Step:

### Go inside the ```Services``` directory , there you can see all thge existing services just you have to copy any of them and make changes as per your requirement .
    
  ##  For Example Let say onboard new service of nginx-2

- copy existing nginx service and paste in the same directory , now change the name of the copied folder to nginx-1

     ```cd service```
     
- now after changing name go inside the directory and inside ```config.yaml``` just you have to replate workspace attributes accordingly:    
       
    ```yaml
        workspaces:
            
            # Environment/Workspace names
            nile-non-baseline:
            container_definitions:
              conatiner_name: "demo"
              cluster_arn: "arn:aws:ecs:us-east-1:476498784073:cluster/ecs-ec2"
              target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:476498784073:targetgroup/demo-ecs-sample/69f3b4a28e134d99"
              image: "nginx:latest"
              containerPort: 80
              protocol: "tcp"
        
            load_balancer:
              container_port: 80
              subnet_ids: ["subnet-0dd96741b19ec4c20", "subnet-0882d12e9929ce102"]
     ```


    - Set the `WORPSPACE` variable (WORPSPACE = ENVIRONMENT)
        ```
        export WORPSPACE=<environment name>
        ```

    - Run the below commands sequentially to deploy the Cluster with Hosts
        ```
        make init
        make plan
        make apply
        ```

        
























