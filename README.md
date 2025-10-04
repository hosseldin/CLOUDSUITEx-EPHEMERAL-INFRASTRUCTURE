# CLOUDSUITEx-EPHEMERAL-INFRASTRUCTURE
This will be a repo for the complete ephemeral CI/CD flow project that will be implemented.

## Setting Up Cloud Environment
I will be using MS Azure for this, so to start, lets setup MS Azure CLI on Ubuntu

For Debian/Ubuntu (Linux):
Update the list of packages and install the necessary dependencies:

``` Bash
sudo apt update\
sudo apt install ca-certificates curl apt-transport-https lsb-release gnupg
```


Download and install the Microsoft signing key:

``` Bash
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
```

Add the Azure CLI repository to your software sources:

``` Bash
AZ_REPO="jammy"\
echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
sudo tee /etc/apt/sources.list.d/azure-cli.list
```

Update the repository and install the CLI:

``` Bash
sudo apt update\
sudo apt install azure-cli
```

Verify the installation:

``` Bash
az version
```

Log in to Azure:

``` Bash
az login --use-device-code

To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code XXXXXXXXX to authenticate.
```

This should now successfully open your web browser for authentication and if successfull shall display on your terminal the tenants and subscriptions available to the account that u signed in.

``` Bash
Retrieving tenants and subscriptions for the selection...

[Tenant and subscription selection]

No     Subscription name    Subscription ID                       Tenant
-----  -------------------  ------------------------------------  -----------------
[1] *  Subscription  XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX  Default Directory

The default is marked with an *; the default tenant is 'Default Directory' and subscription is 'Subscription' (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX).

Select a subscription and tenant (Type a number or Enter for no changes): 1

Tenant: Default Directory
Subscription: Subscription  (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)

[Announcements]
With the new Azure CLI login experience, you can select the subscription you want to use more easily. Learn more about it and its configuration at https://go.microsoft.com/fwlink/?linkid=2271236

If you encounter any problem, please open an issue at https://aka.ms/azclibug

[Warning] The login output has been updated. Please be aware that it no longer displays the full list of available subscriptions by default.
