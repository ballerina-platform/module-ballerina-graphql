package io.ballerina.stdlib.graphql.compiler;

public class CacheConfigContext {
    private Boolean enabled;
    private int maxSize;

    public CacheConfigContext(Boolean enabled, int maxSize) {
        this.enabled = enabled;
        this.maxSize = maxSize;
    }

    public CacheConfigContext(Boolean enabled) {
        this.enabled = enabled;
        this.maxSize = 0;
    }

    public void setEnabled(boolean enabled) {
         this.enabled = enabled;
    }
    public Boolean getEnabled() {
        return enabled;
    }

    public void setMaxSize(int maxSize) {
        if (maxSize > this.maxSize) {
            this.maxSize = maxSize;
        }
    }

    public int getMaxSize() {
        return maxSize;
    }
}
