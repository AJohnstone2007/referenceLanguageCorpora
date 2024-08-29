/*
 * Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

package layout;

import javafx.scene.control.Button;
import javafx.scene.control.Tab;
import javafx.scene.layout.Pane;
import javafx.scene.paint.Color;
import javafx.scene.shape.Circle;
import javafx.scene.shape.Rectangle;

public class PaneTab extends Tab {

    public PaneTab(String text) {
        this.setText(text);
        init();
    }

    public void init() {
        Rectangle rect1 = new Rectangle(450, 450);
        rect1.setLayoutX(150);
        rect1.setLayoutY(80);
        rect1.setFill(Color.BURLYWOOD);

        Rectangle rect2 = new Rectangle(180, 200, 350, 200);
        rect2.setFill(Color.CORAL);

        Circle circle = new Circle(350, 300, 150, Color.GREEN);

        Button okBtn = new Button("OK");
        Button cancelBtn = new Button("Cancel");
        okBtn.relocate(250, 250);
        cancelBtn.relocate(300, 250);

        Pane root = new Pane();
        root.getChildren().addAll(rect1, rect2, circle, okBtn, cancelBtn);
        root.getStyleClass().add("layout");
        this.setContent(root);
    }
}
