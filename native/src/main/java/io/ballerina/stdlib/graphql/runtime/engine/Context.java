package io.ballerina.stdlib.graphql.runtime.engine;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BValue;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * This class provides native implementations of the Ballerina Context class.
 */
public class Context {
    // Provides mapping between user defined id and DataLoader
    private final ConcurrentHashMap<BString, BObject> idDataLoaderMap;
    private final ConcurrentHashMap<BString, BObject> uuidPlaceholderMap;
    private final ConcurrentHashMap<BString, BObject> unResolvedPlaceholders;
    private final AtomicBoolean containPlaceholders;
    // Tracks the number of Placeholders needs to be resolved
    private final AtomicInteger unResolvedPlaceholderCount;
    private final AtomicInteger unResolvedPlaceholderNodeCount;

    private static final String CONTEXT = "context";

    private Context() {
        this.idDataLoaderMap = new ConcurrentHashMap<>();
        this.uuidPlaceholderMap = new ConcurrentHashMap<>();
        this.unResolvedPlaceholders = new ConcurrentHashMap<>();
        this.containPlaceholders = new AtomicBoolean(false);
        this.unResolvedPlaceholderCount = new AtomicInteger(0);
        this.unResolvedPlaceholderNodeCount = new AtomicInteger(0);
    }

    public static void intializeContext(BObject context) {
        context.addNativeData(CONTEXT, new Context());
    }

    public static void registerDataLoader(BObject object, BString key, BObject dataloader) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.registerDataLoader(key, dataloader);
    }

    public static BObject getDataLoader(BObject object, BString key) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getDataLoader(key);
    }

    public static BArray getDataloaderIds(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getDataloaderIds();
    }

    public static BArray getUnresolvedPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getUnresolvedPlaceholders();
    }

    public static void removeAllUnresolvedPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.removeAllUnresolvedPlaceholders();
    }

    public static BObject getPlaceholder(BObject object, BString uuid) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getPlaceholder(uuid);
    }

    public static int getUnresolvedPlaceholderCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getUnresolvedPlaceholderCount();
    }

    public static int getUnresolvedPlaceholderNodeCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.getUnresolvedPlaceholderNodeCount();
    }

    public static void decrementUnresolvedPlaceholderNodeCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.decrementUnresolvedPlaceholderNodeCount();
    }

    public static void decrementUnresolvedPlaceholderCount(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.decrementUnresolvedPlaceholderCount();
    }

    public static void addUnresolvedPlaceholder(BObject object, BString uuid, BObject placeholder) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.addUnresolvedPlaceholder(uuid, placeholder);
    }

    public static boolean hasPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        return context.hasPlaceholders();
    }

    public static void clearPlaceholders(BObject object) {
        Context context = (Context) object.getNativeData(CONTEXT);
        context.clearPlaceholders();
    }

    private void registerDataLoader(BString key, BObject dataloader) {
        this.idDataLoaderMap.put(key, dataloader);
    }

    private BObject getDataLoader(BString key) {
        return this.idDataLoaderMap.get(key);
    }

    private BArray getDataloaderIds() {
        BArray values = ValueCreator.createArrayValue(TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));
        this.idDataLoaderMap.forEach((key, value) -> {
            values.append(key);
        });
        return values;
    }

    private BArray getUnresolvedPlaceholders() {
        Object[] valueArray = this.unResolvedPlaceholders.values().toArray();
        ArrayType arrayType = TypeCreator.createArrayType(((BValue) valueArray[0]).getType());
        BArray values = ValueCreator.createArrayValue(valueArray, arrayType);
        return values;
    }

    private void removeAllUnresolvedPlaceholders() {
        this.unResolvedPlaceholders.clear();
    }

    private BObject getPlaceholder(BString uuid) {
        return this.uuidPlaceholderMap.remove(uuid);
    }

    private int getUnresolvedPlaceholderCount() {
        return this.unResolvedPlaceholderCount.get();
    }

    private int getUnresolvedPlaceholderNodeCount() {
        return this.unResolvedPlaceholderNodeCount.get();
    }

    private void decrementUnresolvedPlaceholderNodeCount() {
        this.unResolvedPlaceholderNodeCount.decrementAndGet();
    }

    private void decrementUnresolvedPlaceholderCount() {
        this.unResolvedPlaceholderCount.decrementAndGet();
    }

    private void addUnresolvedPlaceholder(BString uuid, BObject placeholder) {
        this.containPlaceholders.set(true);
        this.uuidPlaceholderMap.put(uuid, placeholder);
        this.unResolvedPlaceholders.put(uuid, placeholder);
        this.unResolvedPlaceholderCount.incrementAndGet();
        this.unResolvedPlaceholderNodeCount.incrementAndGet();
    }

    private boolean hasPlaceholders() {
        return this.containPlaceholders.get();
    }

    private void clearPlaceholders() {
        this.unResolvedPlaceholders.clear();
        this.uuidPlaceholderMap.clear();
        this.containPlaceholders.set(false);
    }
}
