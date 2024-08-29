/*
 * Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
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
package javafx.scene.control;

import java.time.LocalDate;
import java.time.LocalTime;

public abstract class SpinnerValueFactoryShim<T> extends SpinnerValueFactory<T>  {

    public static void LocalDate_setMin(SpinnerValueFactory<LocalDate> ld, LocalDate d) {
        SpinnerValueFactory.LocalDateSpinnerValueFactory lds = (SpinnerValueFactory.LocalDateSpinnerValueFactory)ld;
        lds.setMin(d);
    }

    public static LocalDate LocalDate_getMin(SpinnerValueFactory<LocalDate> ld) {
        SpinnerValueFactory.LocalDateSpinnerValueFactory lds = (SpinnerValueFactory.LocalDateSpinnerValueFactory)ld;
        return lds.getMin();
    }

    public static void LocalDate_setMax(SpinnerValueFactory<LocalDate> ld, LocalDate d) {
        SpinnerValueFactory.LocalDateSpinnerValueFactory lds = (SpinnerValueFactory.LocalDateSpinnerValueFactory)ld;
        lds.setMax(d);
    }

    public static LocalDate LocalDate_getMax(SpinnerValueFactory<LocalDate> ld) {
        SpinnerValueFactory.LocalDateSpinnerValueFactory lds = (SpinnerValueFactory.LocalDateSpinnerValueFactory)ld;
        return lds.getMax();
    }

    //-----

    public static void LocalTime_setMin(SpinnerValueFactory<LocalTime> ld, LocalTime d) {
        SpinnerValueFactory.LocalTimeSpinnerValueFactory lts = (SpinnerValueFactory.LocalTimeSpinnerValueFactory)ld;
        lts.setMin(d);
    }

    public static LocalTime LocalTime_getMin(SpinnerValueFactory<LocalTime> ld) {
        SpinnerValueFactory.LocalTimeSpinnerValueFactory lts = (SpinnerValueFactory.LocalTimeSpinnerValueFactory)ld;
        return lts.getMin();
    }

    public static void LocalTime_setMax(SpinnerValueFactory<LocalTime> ld, LocalTime d) {
        SpinnerValueFactory.LocalTimeSpinnerValueFactory lts = (SpinnerValueFactory.LocalTimeSpinnerValueFactory)ld;
        lts.setMax(d);
    }

    public static LocalTime LocalTime_getMax(SpinnerValueFactory<LocalTime> ld) {
        SpinnerValueFactory.LocalTimeSpinnerValueFactory lts = (SpinnerValueFactory.LocalTimeSpinnerValueFactory)ld;
        return lts.getMax();
    }

}
