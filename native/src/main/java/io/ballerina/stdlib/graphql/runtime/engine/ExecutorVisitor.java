package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.concurrent.ConcurrentHashMap;

import static io.ballerina.stdlib.graphql.runtime.utils.ModuleUtils.getModule;

public class ExecutorVisitor {
    private static final String DATA_MAP = "dataMap";
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

    private void addData(BString key, Object value) {
        if (value == null) {
            dataMap.put(key, NullObject);
        } else {
            dataMap.put(key, value);
        }
    }

    private BMap<BString, Object> getData() {
        BMap<BString, Object> data = ValueCreator.createRecordValue(getModule(), "Data");
        dataMap.forEach((key, value) -> {
            if (value == NullObject) {
                data.put(key, null);
            } else {
                data.put(key, value);
            }
        });
        return data;
    }

    public static BMap<BString, Object> getDataMap(BObject executorVisitor) {
        ExecutorVisitor visitor = (ExecutorVisitor) executorVisitor.getNativeData(DATA_MAP);
        return visitor.getData();
    }
}
