package test.javafx.scene.control;
import javafx.scene.control.skin.ListCellSkin;
import test.com.sun.javafx.scene.control.infrastructure.StageLoader;
import javafx.beans.InvalidationListener;
import javafx.collections.FXCollections;
import javafx.collections.ListChangeListener;
import javafx.collections.ObservableList;
import javafx.scene.control.FocusModel;
import javafx.scene.control.ListCell;
import javafx.scene.control.ListCellShim;
import javafx.scene.control.ListView;
import javafx.scene.control.ListView.EditEvent;
import javafx.scene.control.MultipleSelectionModel;
import javafx.scene.control.MultipleSelectionModelBaseShim;
import javafx.scene.control.SelectionMode;
import java.util.List;
import java.util.ArrayList;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import com.sun.javafx.tk.Toolkit;
import static javafx.scene.control.ControlShim.*;
import static test.com.sun.javafx.scene.control.infrastructure.ControlTestUtils.*;
import static org.junit.Assert.*;
public class ListCellTest {
private ListCell<String> cell;
private ListView<String> list;
private ObservableList<String> model;
private StageLoader stageLoader;
@Before public void setup() {
Thread.currentThread().setUncaughtExceptionHandler((thread, throwable) -> {
if (throwable instanceof RuntimeException) {
throw (RuntimeException)throwable;
} else {
Thread.currentThread().getThreadGroup().uncaughtException(thread, throwable);
}
});
cell = new ListCell<String>();
model = FXCollections.observableArrayList("Apples", "Oranges", "Pears");
list = new ListView<String>(model);
}
@After public void cleanup() {
if (stageLoader != null) stageLoader.dispose();
Thread.currentThread().setUncaughtExceptionHandler(null);
}
@Test public void styleClassIs_list_cell_byDefault() {
assertStyleClassContains(cell, "list-cell");
}
@Test public void itemIsNullByDefault() {
assertNull(cell.getItem());
}
@Test public void listViewIsNullByDefault() {
assertNull(cell.getListView());
assertNull(cell.listViewProperty().get());
}
@Test public void updateListViewUpdatesListView() {
cell.updateListView(list);
assertSame(list, cell.getListView());
assertSame(list, cell.listViewProperty().get());
}
@Test public void canSetListViewBackToNull() {
cell.updateListView(list);
cell.updateListView(null);
assertNull(cell.getListView());
assertNull(cell.listViewProperty().get());
}
@Test public void listViewPropertyReturnsCorrectBean() {
assertSame(cell, cell.listViewProperty().getBean());
}
@Test public void listViewPropertyNameIs_listView() {
assertEquals("listView", cell.listViewProperty().getName());
}
@Test public void updateListViewWithNullFocusModelResultsInNoException() {
cell.updateListView(list);
list.setFocusModel(null);
cell.updateListView(new ListView());
}
@Test public void updateListViewWithNullFocusModelResultsInNoException2() {
list.setFocusModel(null);
cell.updateListView(list);
cell.updateListView(new ListView());
}
@Test public void updateListViewWithNullFocusModelResultsInNoException3() {
cell.updateListView(list);
ListView list2 = new ListView();
list2.setFocusModel(null);
cell.updateListView(list2);
}
@Test public void updateListViewWithNullSelectionModelResultsInNoException() {
cell.updateListView(list);
list.setSelectionModel(null);
cell.updateListView(new ListView());
}
@Test public void updateListViewWithNullSelectionModelResultsInNoException2() {
list.setSelectionModel(null);
cell.updateListView(list);
cell.updateListView(new ListView());
}
@Test public void updateListViewWithNullSelectionModelResultsInNoException3() {
cell.updateListView(list);
ListView list2 = new ListView();
list2.setSelectionModel(null);
cell.updateListView(list2);
}
@Test public void updateListViewWithNullItemsResultsInNoException() {
cell.updateListView(list);
list.setItems(null);
cell.updateListView(new ListView());
}
@Test public void updateListViewWithNullItemsResultsInNoException2() {
list.setItems(null);
cell.updateListView(list);
cell.updateListView(new ListView());
}
@Test public void updateListViewWithNullItemsResultsInNoException3() {
cell.updateListView(list);
ListView list2 = new ListView();
list2.setItems(null);
cell.updateListView(list2);
}
@Test public void itemMatchesIndexWithinListItems() {
cell.updateIndex(0);
cell.updateListView(list);
assertSame(model.get(0), cell.getItem());
cell.updateIndex(1);
assertSame(model.get(1), cell.getItem());
}
@Test public void itemMatchesIndexWithinListItems2() {
cell.updateListView(list);
cell.updateIndex(0);
assertSame(model.get(0), cell.getItem());
cell.updateIndex(1);
assertSame(model.get(1), cell.getItem());
}
@Test public void itemIsNullWhenIndexIsOutOfRange() {
cell.updateIndex(50);
cell.updateListView(list);
assertNull(cell.getItem());
}
@Test public void itemIsNullWhenIndexIsOutOfRange2() {
cell.updateListView(list);
cell.updateIndex(50);
assertNull(cell.getItem());
}
@Test public void itemIsUpdatedWhenItWasOutOfRangeButUpdatesToListViewItemsMakesItInRange() {
cell.updateIndex(4);
cell.updateListView(list);
model.addAll("Pumpkin", "Lemon");
assertSame(model.get(4), cell.getItem());
}
@Test public void itemIsUpdatedWhenItWasInRangeButUpdatesToListViewItemsMakesItOutOfRange() {
cell.updateIndex(2);
cell.updateListView(list);
assertSame(model.get(2), cell.getItem());
model.remove(2);
assertNull(cell.getItem());
}
@Test public void itemIsUpdatedWhenListViewItemsIsUpdated() {
cell.updateIndex(1);
cell.updateListView(list);
assertSame(model.get(1), cell.getItem());
model.set(1, "Lime");
assertEquals("Lime", cell.getItem());
}
@Test public void itemIsUpdatedWhenListViewItemsHasNewItemInsertedBeforeIndex() {
cell.updateIndex(1);
cell.updateListView(list);
assertSame(model.get(1), cell.getItem());
String previous = model.get(0);
model.add(0, "Lime");
assertEquals(previous, cell.getItem());
}
@Test public void itemIsUpdatedWhenListViewItemsHasItemRemovedBeforeIndex() {
cell.updateIndex(1);
cell.updateListView(list);
assertSame(model.get(1), cell.getItem());
String other = model.get(2);
model.remove(0);
assertEquals(other, cell.getItem());
}
@Test public void itemIsUpdatedWhenListViewItemsIsReplaced() {
ObservableList<String> model2 = FXCollections.observableArrayList("Water", "Juice", "Soda");
cell.updateIndex(1);
cell.updateListView(list);
list.setItems(model2);
assertEquals("Juice", cell.getItem());
}
@Test public void itemIsUpdatedWhenListViewIsReplaced() {
cell.updateIndex(2);
cell.updateListView(list);
ObservableList<String> model2 = FXCollections.observableArrayList("Water", "Juice", "Soda");
ListView<String> listView2 = new ListView<String>(model2);
cell.updateListView(listView2);
assertEquals("Soda", cell.getItem());
}
@Test public void replaceItemsWithANull() {
cell.updateIndex(0);
cell.updateListView(list);
list.setItems(null);
assertNull(cell.getItem());
}
@Test public void replaceItemsWithANull_ListenersRemovedFromFormerList() {
cell.updateIndex(0);
cell.updateListView(list);
ListChangeListener listener = getListChangeListener(cell, "weakItemsListener");
assertListenerListContains(model, listener);
list.setItems(null);
assertListenerListDoesNotContain(model, listener);
}
@Test public void replaceANullItemsWithNotNull() {
cell.updateIndex(0);
cell.updateListView(list);
list.setItems(null);
ObservableList<String> model2 = FXCollections.observableArrayList("Water", "Juice", "Soda");
list.setItems(model2);
assertEquals("Water", cell.getItem());
}
@Test
public void testNullItemRemoveAsLast() {
model.add(null);
cell.updateListView(list);
int last = model.size() - 1;
cell.updateIndex(last);
model.remove(last);
assertOffRangeState(last);
}
@Test
public void testNullItemRemoveAsFirst() {
int first = 0;
model.add(first, null);
cell.updateListView(list);
cell.updateIndex(first);
model.remove(first);
assertInRangeState(first);
}
@Test
public void testNullItemUpdateIndexOffRange() {
model.add(0, null);
cell.updateListView(list);
cell.updateIndex(0);
cell.updateIndex(model.size());
assertOffRangeState(model.size());
}
@Test
public void testNullItemUpdateIndexNegative() {
model.add(0, null);
cell.updateListView(list);
cell.updateIndex(0);
cell.updateIndex(-1);
assertOffRangeState(-1);
}
@Test
public void testNullItem() {
model.add(0, null);
cell.updateListView(list);
cell.updateIndex(0);
assertInRangeState(0);
}
protected void assertOffRangeState(int index) {
assertEquals("off range index", index, cell.getIndex());
assertNull("off range cell item must be null", cell.getItem());
assertTrue("off range cell must be empty", cell.isEmpty());
}
protected void assertInRangeState(int index) {
assertEquals("in range index", index, cell.getIndex());
assertEquals("in range cell item must be same as model item", model.get(index), cell.getItem());
assertFalse("in range cell must not be empty", cell.isEmpty());
}
@Test public void selectionOnSelectionModelIsReflectedInCells() {
cell.updateListView(list);
cell.updateIndex(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
list.getSelectionModel().selectFirst();
assertTrue(cell.isSelected());
assertFalse(other.isSelected());
}
@Test public void changesToSelectionOnSelectionModelAreReflectedInCells() {
cell.updateListView(list);
cell.updateIndex(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
list.getSelectionModel().selectFirst();
list.getSelectionModel().selectNext();
assertFalse(cell.isSelected());
assertTrue(other.isSelected());
}
@Test public void replacingTheSelectionModelCausesSelectionOnCellsToBeUpdated() {
cell.updateListView(list);
cell.updateIndex(0);
list.getSelectionModel().select(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
MultipleSelectionModel<String> selectionModel = new SelectionModelMock();
selectionModel.select(1);
list.setSelectionModel(selectionModel);
assertFalse(cell.isSelected());
assertTrue(other.isSelected());
}
@Test public void changesToSelectionOnSelectionModelAreReflectedInCells_MultipleSelection() {
list.getSelectionModel().setSelectionMode(SelectionMode.MULTIPLE);
cell.updateListView(list);
cell.updateIndex(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
list.getSelectionModel().selectFirst();
list.getSelectionModel().selectNext();
assertTrue(cell.isSelected());
assertTrue(other.isSelected());
}
@Test public void replacingTheSelectionModelCausesSelectionOnCellsToBeUpdated_MultipleSelection() {
cell.updateListView(list);
cell.updateIndex(0);
list.getSelectionModel().select(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
MultipleSelectionModel<String> selectionModel = new SelectionModelMock();
selectionModel.setSelectionMode(SelectionMode.MULTIPLE);
selectionModel.selectIndices(0, 1);
list.setSelectionModel(selectionModel);
assertTrue(cell.isSelected());
assertTrue(other.isSelected());
}
@Test public void replaceANullSelectionModel() {
list.setSelectionModel(null);
cell.updateIndex(0);
cell.updateListView(list);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
MultipleSelectionModel<String> selectionModel = new SelectionModelMock();
selectionModel.select(1);
list.setSelectionModel(selectionModel);
assertFalse(cell.isSelected());
assertTrue(other.isSelected());
}
@Test public void setANullSelectionModel() {
cell.updateIndex(0);
cell.updateListView(list);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
list.setSelectionModel(null);
assertFalse(cell.isSelected());
assertFalse(other.isSelected());
}
@Test public void replacingTheSelectionModelRemovesTheListenerFromTheOldModel() {
cell.updateIndex(0);
cell.updateListView(list);
MultipleSelectionModel<String> sm = list.getSelectionModel();
ListChangeListener listener = getListChangeListener(cell, "weakSelectedListener");
assertListenerListContains(sm.getSelectedIndices(), listener);
list.setSelectionModel(new SelectionModelMock());
assertListenerListDoesNotContain(sm.getSelectedIndices(), listener);
}
@Test public void focusOnFocusModelIsReflectedInCells() {
cell.updateListView(list);
cell.updateIndex(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
list.getFocusModel().focus(0);
assertTrue(cell.isFocused());
assertFalse(other.isFocused());
}
@Test public void changesToFocusOnFocusModelAreReflectedInCells() {
cell.updateListView(list);
cell.updateIndex(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
list.getFocusModel().focus(0);
list.getFocusModel().focus(1);
assertFalse(cell.isFocused());
assertTrue(other.isFocused());
}
@Test public void replacingTheFocusModelCausesFocusOnCellsToBeUpdated() {
cell.updateListView(list);
cell.updateIndex(0);
list.getFocusModel().focus(0);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
FocusModel<String> focusModel = new FocusModelMock();
focusModel.focus(1);
list.setFocusModel(focusModel);
assertFalse(cell.isFocused());
assertTrue(other.isFocused());
}
@Test public void replaceANullFocusModel() {
list.setFocusModel(null);
cell.updateIndex(0);
cell.updateListView(list);
ListCell<String> other = new ListCell<String>();
other.updateListView(list);
other.updateIndex(1);
FocusModel<String> focusModel = new FocusModelMock();
focusModel.focus(1);
list.setFocusModel(focusModel);
assertFalse(cell.isFocused());
assertTrue(other.isFocused());
}
@Test public void setANullFocusModel() {
cell.updateIndex(0);
cell.updateListView(list);
ListCell<String> other = new ListCell<>();
other.updateListView(list);
other.updateIndex(1);
list.setFocusModel(null);
assertFalse(cell.isFocused());
assertFalse(other.isFocused());
}
@Test public void replacingTheFocusModelRemovesTheListenerFromTheOldModel() {
cell.updateIndex(0);
cell.updateListView(list);
FocusModel<String> fm = list.getFocusModel();
InvalidationListener listener = getInvalidationListener(cell, "weakFocusedListener");
assertValueListenersContains(fm.focusedIndexProperty(), listener);
list.setFocusModel(new FocusModelMock());
assertValueListenersDoesNotContain(fm.focusedIndexProperty(), listener);
}
@Test public void editOnListViewResultsInEditingInCell() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
list.edit(1);
assertTrue(cell.isEditing());
}
@Test public void editOnListViewResultsInNotEditingInCellWhenDifferentIndex() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
list.edit(0);
assertFalse(cell.isEditing());
}
@Test public void editCellWithNullListViewResultsInNoExceptions() {
cell.updateIndex(1);
cell.startEdit();
}
@Test public void editCellOnNonEditableListDoesNothing() {
cell.updateIndex(1);
cell.updateListView(list);
cell.startEdit();
assertFalse(cell.isEditing());
assertEquals(-1, list.getEditingIndex());
}
@Test public void editCellWithListResultsInUpdatedEditingIndexProperty() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
cell.startEdit();
assertEquals(1, list.getEditingIndex());
}
@Test public void editCellFiresEventOnList() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(2);
final boolean[] called = new boolean[] { false };
list.setOnEditStart(event -> {
called[0] = true;
});
cell.startEdit();
assertTrue(called[0]);
}
@Test public void editCellDoesNotFireEventWhileAlreadyEditing() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(2);
cell.startEdit();
List<EditEvent<?>> events = new ArrayList<>();
list.setOnEditStart(events::add);
cell.startEdit();
assertEquals("startEdit must not fire event while editing", 0, events.size());
}
@Test public void commitWhenListIsNullIsOK() {
cell.updateIndex(1);
cell.startEdit();
cell.commitEdit("Watermelon");
}
@Test public void commitWhenListIsNotNullWillUpdateTheItemsList() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
cell.startEdit();
cell.commitEdit("Watermelon");
assertEquals("Watermelon", list.getItems().get(1));
}
@Test public void commitSendsEventToList() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
cell.startEdit();
final boolean[] called = new boolean[] { false };
list.setOnEditCommit(event -> {
called[0] = true;
});
cell.commitEdit("Watermelon");
assertTrue(called[0]);
}
@Test public void afterCommitListViewEditingIndexIsNegativeOne() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
cell.startEdit();
cell.commitEdit("Watermelon");
assertEquals(-1, list.getEditingIndex());
assertFalse(cell.isEditing());
}
@Test public void cancelEditCanBeCalledWhileListViewIsNull() {
cell.updateIndex(1);
cell.startEdit();
cell.cancelEdit();
}
@Test public void cancelEditFiresChangeEvent() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
cell.startEdit();
final boolean[] called = new boolean[] { false };
list.setOnEditCancel(event -> {
called[0] = true;
});
cell.cancelEdit();
assertTrue(called[0]);
}
@Test public void cancelSetsListViewEditingIndexToNegativeOne() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(1);
cell.startEdit();
cell.cancelEdit();
assertEquals(-1, list.getEditingIndex());
assertFalse(cell.isEditing());
}
@Test public void movingListCellEditingIndexCausesCurrentlyInEditCellToCancel() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(0);
cell.startEdit();
ListCell other = new ListCell();
other.updateListView(list);
other.updateIndex(1);
list.edit(1);
assertTrue(other.isEditing());
assertFalse(cell.isEditing());
}
@Test
public void testEditCancelEventAfterCancelOnCell() {
list.setEditable(true);
cell.updateListView(list);
int editingIndex = 1;
cell.updateIndex(editingIndex);
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
cell.cancelEdit();
assertEquals(1, events.size());
assertEquals("editing location of cancel event", editingIndex, events.get(0).getIndex());
}
@Test
public void testEditCancelEventAfterCancelOnList() {
list.setEditable(true);
cell.updateListView(list);
int editingIndex = 1;
cell.updateIndex(editingIndex);
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
list.edit(-1);
assertEquals(1, events.size());
assertEquals("editing location of cancel event", editingIndex, events.get(0).getIndex());
}
@Test
public void testEditCancelEventAfterChangeEditingIndexOnList() {
list.setEditable(true);
cell.updateListView(list);
int editingIndex = 1;
cell.updateIndex(editingIndex);
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
list.edit(0);
assertEquals(1, events.size());
assertEquals("editing location of cancel event", editingIndex, events.get(0).getIndex());
}
@Test
public void testEditCancelEventAfterCellReuse() {
list.setEditable(true);
cell.updateListView(list);
int editingIndex = 1;
cell.updateIndex(editingIndex);
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
cell.updateIndex(0);
assertEquals(1, events.size());
assertEquals("editing location of cancel event", editingIndex, events.get(0).getIndex());
}
@Test
public void testEditCancelEventAfterModifyItems() {
list.setEditable(true);
stageLoader = new StageLoader(list);
int editingIndex = 1;
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
list.getItems().add(0, "added");
Toolkit.getToolkit().firePulse();
assertEquals(1, events.size());
assertEquals("editing location of cancel event", editingIndex, events.get(0).getIndex());
}
@Test
public void testEditCancelEventAfterRemoveEditingItem() {
list.setEditable(true);
stageLoader = new StageLoader(list);
int editingIndex = 1;
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
list.getItems().remove(editingIndex);
Toolkit.getToolkit().firePulse();
assertEquals("removing item must cancel edit on list", -1, list.getEditingIndex());
assertEquals(1, events.size());
assertEquals("editing location of cancel event", editingIndex, events.get(0).getIndex());
}
@Test
public void testStartEditOffRangeMustNotFireStartEdit() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(list.getItems().size());
List<EditEvent<?>> events = new ArrayList<>();
list.addEventHandler(ListView.editStartEvent(), events::add);
cell.startEdit();
assertFalse("sanity: off-range cell must not be editing", cell.isEditing());
assertEquals("must not fire editStart", 0, events.size());
}
@Test
public void testStartEditOffRangeMustNotUpdateEditingLocation() {
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(list.getItems().size());
cell.startEdit();
assertFalse("sanity: off-range cell must not be editing", cell.isEditing());
assertEquals("list editing location must not be updated", -1, list.getEditingIndex());
}
@Test
public void testCommitEditMustNotFireCancel() {
list.setEditable(true);
list.setOnEditCommit(e -> {
int index = e.getIndex();
list.getItems().set(index, e.getNewValue());
list.edit(-1);
});
cell.updateListView(list);
int editingIndex = 1;
cell.updateIndex(editingIndex);
list.edit(editingIndex);
List<EditEvent<String>> events = new ArrayList<>();
list.setOnEditCancel(events::add);
String value = "edited";
cell.commitEdit(value);
assertEquals("sanity: value committed", value, list.getItems().get(editingIndex));
assertEquals("commit must not have fired editCancel", 0, events.size());
}
private final class SelectionModelMock extends MultipleSelectionModelBaseShim<String> {
@Override protected int getItemCount() {
return model.size();
}
@Override protected String getModelItem(int index) {
return model.get(index);
}
@Override protected void focus(int index) {
}
@Override protected int getFocusedIndex() {
return list.getFocusModel().getFocusedIndex();
}
};
private final class FocusModelMock extends FocusModel {
@Override protected int getItemCount() {
return model.size();
}
@Override protected Object getModelItem(int row) {
return model.get(row);
}
}
private int rt_29923_count = 0;
@Test public void test_rt_29923() {
cell = new ListCellShim<String>() {
@Override public void updateItem(String item, boolean empty) {
super.updateItem(item, empty);
rt_29923_count++;
}
};
list.getItems().setAll(null, null, null);
cell.updateListView(list);
rt_29923_count = 0;
cell.updateIndex(0);
assertNull(cell.getItem());
assertFalse(cell.isEmpty());
assertEquals(1, rt_29923_count);
cell.updateIndex(1);
assertNull(cell.getItem());
assertFalse(cell.isEmpty());
assertEquals(2, rt_29923_count);
}
@Test public void test_rt_33106() {
cell.updateListView(list);
list.setItems(null);
cell.updateIndex(1);
}
@Test public void test_jdk_8151524() {
ListCell cell = new ListCell();
cell.setSkin(new ListCellSkin(cell));
}
@Test
public void testListCellHeights() {
ListCell<Object> cell = new ListCell<>();
ListView<Object> listView = new ListView<>();
cell.updateListView(listView);
installDefaultSkin(cell);
listView.setFixedCellSize(100);
assertEquals("pref height must be fixedCellSize",
listView.getFixedCellSize(),
cell.prefHeight(-1), 1);
assertEquals("min height must be fixedCellSize",
listView.getFixedCellSize(),
cell.minHeight(-1), 1);
assertEquals("max height must be fixedCellSize",
listView.getFixedCellSize(),
cell.maxHeight(-1), 1);
}
@Test
public void testChangeIndexToEditing1_jdk_8264127() {
assertChangeIndexToEditing(0, 1);
}
@Test
public void testChangeIndexToEditing2_jdk_8264127() {
assertChangeIndexToEditing(-1, 1);
}
@Test
public void testChangeIndexToEditing3_jdk_8264127() {
assertChangeIndexToEditing(1, 0);
}
@Test
public void testChangeIndexToEditing4_jdk_8264127() {
assertChangeIndexToEditing(-1, 0);
}
private void assertChangeIndexToEditing(int initialCellIndex, int listEditingIndex) {
list.getFocusModel().focus(-1);
List<EditEvent> events = new ArrayList<EditEvent>();
list.setOnEditStart(e -> {
events.add(e);
});
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(initialCellIndex);
list.edit(listEditingIndex);
assertEquals("sanity: list editingIndex ", listEditingIndex, list.getEditingIndex());
assertFalse("sanity: cell must not be editing", cell.isEditing());
cell.updateIndex(listEditingIndex);
assertEquals("sanity: index updated ", listEditingIndex, cell.getIndex());
assertEquals("list editingIndex unchanged by cell", listEditingIndex, list.getEditingIndex());
assertTrue(cell.isEditing());
assertEquals(1, events.size());
}
@Test
public void testChangeIndexOffEditing0_jdk_8264127() {
assertUpdateCellIndexOffEditing(1, 0);
}
@Test
public void testChangeIndexOffEditing1_jdk_8264127() {
assertUpdateCellIndexOffEditing(1, -1);
}
@Test
public void testChangeIndexOffEditing2_jdk_8264127() {
assertUpdateCellIndexOffEditing(0, 1);
}
@Test
public void testChangeIndexOffEditing3_jdk_8264127() {
assertUpdateCellIndexOffEditing(0, -1);
}
public void assertUpdateCellIndexOffEditing(int editingIndex, int cancelIndex) {
list.getFocusModel().focus(-1);
List<EditEvent> events = new ArrayList<EditEvent>();
list.setOnEditCancel(e -> {
events.add(e);
});
list.setEditable(true);
cell.updateListView(list);
cell.updateIndex(editingIndex);
list.edit(editingIndex);
assertEquals("sanity: list editingIndex ", editingIndex, list.getEditingIndex());
assertTrue("sanity: cell must be editing", cell.isEditing());
cell.updateIndex(cancelIndex);
assertEquals("sanity: index updated ", cancelIndex, cell.getIndex());
assertEquals("list editingIndex unchanged by cell", editingIndex, list.getEditingIndex());
assertFalse("cell must not be editing if cell index is " + cell.getIndex(), cell.isEditing());
assertEquals(1, events.size());
}
@Test
public void testMisbehavingCancelEditTerminatesEdit() {
ListCell<String> cell = new MisbehavingOnCancelListCell<>();
list.setEditable(true);
cell.updateListView(list);
int editingIndex = 1;
int intermediate = 0;
int notEditingIndex = -1;
cell.updateIndex(editingIndex);
list.edit(editingIndex);
assertTrue("sanity: ", cell.isEditing());
try {
list.edit(intermediate);
} catch (Exception ex) {
} finally {
assertFalse("cell must not be editing", cell.isEditing());
assertEquals("list must be editing at intermediate index", intermediate, list.getEditingIndex());
}
list.edit(editingIndex);
assertTrue("sanity: ", cell.isEditing());
try {
cell.cancelEdit();
} catch (Exception ex) {
} finally {
assertFalse("cell must not be editing", cell.isEditing());
assertEquals("list editing must be cancelled by cell", notEditingIndex, list.getEditingIndex());
}
}
public static class MisbehavingOnCancelListCell<T> extends ListCell<T> {
@Override
public void cancelEdit() {
super.cancelEdit();
throw new RuntimeException("violating contract");
}
}
}