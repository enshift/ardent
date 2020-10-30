@isTest
private class CollectionTest {
  @isTest
  static void canCreateCollectionFromSObjects() {
    List<Account> accounts = new List<Account>{
      new Account(Name = 'First Account'),
      new Account(Name = 'Second Account')
    };

    insert accounts;

    Collection accountCollection = Collection.newInstance(
      TestAccount.class,
      accounts
    );
  }
}
