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
}
