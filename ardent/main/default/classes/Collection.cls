public with sharing class Collection {
  private Map<String, Model> modelByKey;

  public Collection() {
    modelByKey = new Map<String, Model>();
  }
}
