# Ardent
Ardent aims to deliver ORM functionality as seen in Laravel's Eloquent to Apex.

## Architecture
### Models

Models are basically wrappers around SObjects enriching them with ORM functionality and containing the Domain business logic, much like domain classes in the `fflib` framework.

In theory, you could name your Models anything you want, but we would advise on enforcing a naming convention that avoids naming collisions with SObjects (ie: not naming your model Account as you would run into collisions with the Account SObject class).

A sensible convention would be for example to name your models exactly after the corresponding SObject, suffixed with 'M' for Model.

|SObject|Model|
|-|-|
|Account|AccountM|
|Publisher__c|PublisherM|
|Account_Publisher__c|AccountPublisherM|

### Retrieving and Collections

Ardent Models aim to be a powerful query builder, allowing you to easily query the Model's table and its relationships.

```java
PublisherM publisher = (PublisherM)PublisherM.where('Id', (Id)recordId).first();
```

Multiple models are contained in a ArCollection class:

```java
ArCollection publishers = PublisherM.whereIn('Id', (Set<Id>)recordIds).all();
```
