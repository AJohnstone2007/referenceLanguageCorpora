package javafx.beans.binding;
import javafx.beans.InvalidationListener;
import javafx.beans.Observable;
import javafx.beans.value.ChangeListener;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import com.sun.javafx.binding.BindingHelperObserver;
import com.sun.javafx.binding.ExpressionHelper;
public abstract class StringBinding extends StringExpression implements
Binding<String> {
private String value;
private boolean valid = false;
private BindingHelperObserver observer;
private ExpressionHelper<String> helper = null;
public StringBinding() {
}
@Override
public void addListener(InvalidationListener listener) {
helper = ExpressionHelper.addListener(helper, this, listener);
}
@Override
public void removeListener(InvalidationListener listener) {
helper = ExpressionHelper.removeListener(helper, listener);
}
@Override
public void addListener(ChangeListener<? super String> listener) {
helper = ExpressionHelper.addListener(helper, this, listener);
}
@Override
public void removeListener(ChangeListener<? super String> listener) {
helper = ExpressionHelper.removeListener(helper, listener);
}
protected final void bind(Observable... dependencies) {
if ((dependencies != null) && (dependencies.length > 0)) {
if (observer == null) {
observer = new BindingHelperObserver(this);
}
for (final Observable dep : dependencies) {
dep.addListener(observer);
}
}
}
protected final void unbind(Observable... dependencies) {
if (observer != null) {
for (final Observable dep : dependencies) {
dep.removeListener(observer);
}
observer = null;
}
}
@Override
public void dispose() {
}
@Override
public ObservableList<?> getDependencies() {
return FXCollections.emptyObservableList();
}
@Override
public final String get() {
if (!valid) {
value = computeValue();
valid = true;
}
return value;
}
protected void onInvalidating() {
}
@Override
public final void invalidate() {
if (valid) {
valid = false;
onInvalidating();
ExpressionHelper.fireValueChangedEvent(helper);
}
}
@Override
public final boolean isValid() {
return valid;
}
protected abstract String computeValue();
@Override
public String toString() {
return valid ? "StringBinding [value: " + get() + "]"
: "StringBinding [invalid]";
}
}