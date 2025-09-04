import { EasePick } from "@easepick/bundle/dist";

let Calendar = {
  mounted() {
    this.picker = new EasePick({
      element: this.el,
      plugins: ['RangePlugin'],
      RangePlugin: {
        tooltip: true
      },
      setup: (picker) => {
        picker.on('select', (e) => {
          const range = picker.getDateRange();
          if (!range || !range.start || !range.end) return;
          this.pushEvent("dates-picked", [range.start.toISOString(), range.end.toISOString()]);
        });
      }
    });
  },
  destroyed() {
    if (this.picker) {
      this.picker.destroy();
    }
  }
};

export default Calendar;