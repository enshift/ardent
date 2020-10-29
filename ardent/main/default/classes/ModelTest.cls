@isTest
private class ModelTest {
  @isTest
  static void canCreateNewInstance() {
    TestAccount account = (TestAccount) Model.newInstance(TestAccount.class);

    System.assertNotEquals(
      null,
      account,
      'newInstance should provision a new Model'
    );
  }

  @isTest
  static void canCreateNewInstanceFromSObject() {
    Id testId =
      Account.getSObjectType().getDescribe().getKeyPrefix() + '000000000001';
    Account accountSObject = new Account(Id = testId);
    TestAccount account = (TestAccount) Model.newInstance(
      TestAccount.class,
      accountSObject
    );

    System.assertEquals(
      String.valueOf(testId),
      account.key,
      'newInstance should provision a new Model with a key value of the Id of the passed SObject'
    );

    System.assertEquals(
      accountSObject,
      account.record,
      'newInstance should provision a new Model with record of the passed SObject'
    );
  }

  @isTest
  static void generatesUniqueKeysForNewSObjects() {
    TestAccount account = (TestAccount) Model.newInstance(TestAccount.class);
    TestContact contact = (TestContact) Model.newInstance(TestContact.class);

    System.assertEquals(
      '0',
      account.key,
      'First created Model without existing SObject should get key 0'
    );
    System.assertEquals(
      '1',
      contact.key,
      'First created Model without existing SObject should get key 1'
    );
  }
}
