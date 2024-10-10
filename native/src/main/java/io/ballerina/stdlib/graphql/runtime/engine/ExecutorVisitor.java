package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.concurrent.ConcurrentHashMap;

import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

/**
 * This class provides native implementations of the Ballerina ExecutorVisitor class.
 */
public class ExecutorVisitor {
    private static final String DATA_MAP = "dataMap";
    private static final String DATA_RECORD_NAME = "Data";
    private static final Object NullObject = new Object();
    private final ConcurrentHashMap<BString, Object> dataMap;

    private ExecutorVisitor() {
        dataMap = new ConcurrentHashMap<>();
    }

    public static void initializeDataMap(BObject executorVisitor) {
        executorVisitor.addNativeData(DATA_MAP, new ExecutorVisitor());
    }

    public static void addData(BObject executorVisitor, BString key, Object value) {
        ExecutorVisitor visitor = (ExecutorVisitor) executorVisitor.getNativeData(DATA_MAP);
        visitor.addData(key, value);
    }

    public static BMap<BString, Object> getDataMap(BObject executorVisitor) {
        ExecutorVisitor visitor = (ExecutorVisitor) executorVisitor.getNativeData(DATA_MAP);
        return visitor.getDataMap();
    }

    private void addData(BString key, Object value) {
        if (value == null) {
            dataMap.put(key, NullObject);
        } else {
            dataMap.put(key, value);
        }
    }

    private BMap<BString, Object> getDataMap() {
        BMap<BString, Object> data = ValueCreator.createRecordValue(getModule(), DATA_RECORD_NAME);
        dataMap.forEach((key, value) -> {
            if (value.equals(NullObject)) {
                data.put(key, null);
            } else {
                data.put(key, value);
            }
        });
        return data;
    }
}
