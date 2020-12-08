@isTest
private class SObjectMetadataTest {
  @isTest
  private static void getFieldNamesShouldThrowErrorWithWrongArgument() {
    try {
      SObjectMetadata.getFieldNames('Spontact', 'ContactFieldset');
    } catch (Exception e) {
      System.assertEquals(
        SObjectMetadata.EXCEPTION_SOBJECTNAME_NOT_FOUND,
        e.getMessage()
      );
    }
  }
}
