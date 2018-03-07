class BoxModel {
    constructor() {
        this.parentWidth = 0;
        this.parentHeight = 0;
        this.margin = { top: 0, right: 0, bottom: 0, left: 0 };
        this.width = 0;
        this.height = 0;
    }

    withParentWidth(w) {
        this.parentWidth = w;
        return this;
    }

    withParentHeight(h) {
        this.parentHeight = h;
        return this;
    }

    withMargins(a, b, c, d) {
        this.margin.top = a;
        this.margin.right = b;
        this.margin.bottom = c;
        this.margin.left = d;
        this.updateWidth();
        this.updateHeight();
        return this;
    }

    updateWidth() {
        this.width = this.parentWidth - this.margin.left - this.margin.right;
    }

    updateHeight() {
        this.height = this.parentHeight - this.margin.top - this.margin.bottom;
    }
}