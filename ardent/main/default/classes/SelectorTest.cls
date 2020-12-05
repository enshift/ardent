@isTest
private class SelectorTest {
  @isTest
  static void shouldQueryAllFieldsByDefault() {
    Selector accountSelector = new Selector(Schema.Account.sobjectType);
    String query = accountSelector.getQuery();

    System.assertEquals(true, query.containsIgnoreCase('owner'));
    System.assertEquals(true, query.containsIgnoreCase('billingcountry'));
    System.assertEquals(true, query.containsIgnoreCase('accountsource'));
    System.assertEquals(true, query.containsIgnoreCase('annualrevenue'));
  }
}
