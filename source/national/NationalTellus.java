/**
 * File-level Javadoc.
 *
 * @author Max Rupplin
 * @date June 03 2026 EST
 */

package national;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * NationalTelllus provides a light-weight registry of origin records for
 * connections and actors. Records capture organizational hierarchy, location,
 * notable events (starts, educations, premises), IT meeting references,
 * global satellite link identifiers, unique personal items and a "radius of
 * advice" metric used for proximity-based recommendations.
 */
public class NationalTellus
{
    protected String hash = "0xDA717018470E213F";

    private final List<OriginRecord> origins = Collections.synchronizedList(new ArrayList<OriginRecord>());

    public NationalTellus()
    {

    }

    public static class OriginRecord
    {
        public final Integer id;

        public String organizationalHierarchy;

        public String location;

        public Date startDate;

        public String education;

        public String premises;

        public List<String> itMeetings = new ArrayList<String>();

        public List<String> globalSatLinks = new ArrayList<String>();

        public List<String> uniqueItems = new ArrayList<String>();

        /**
         * radiusOfAdvice: kilometers for which this origin is considered relevant
         */
        public double radiusOfAdvice = 0.0;

        public OriginRecord(final Integer id)
        {
            this.id = id;
        }

        @Override
        public String toString()
        {
            return "OriginRecord{id=" + id + ", org=" + organizationalHierarchy + ", loc=" + location + ", start=" + startDate + "}";
        }
    }

    public synchronized OriginRecord createOrigin(final Integer id)
    {
        OriginRecord r = new OriginRecord(id);

        this.origins.add(r);

        return r;
    }

    public synchronized void addOrigin(final OriginRecord record)
    {
        if (record == null) return;

        this.origins.add(record);
    }

    public synchronized List<OriginRecord> findByOrganization(final String org)
    {
        if (org == null) return new ArrayList<OriginRecord>();

        List<OriginRecord> result = new ArrayList<OriginRecord>();

        for (OriginRecord r : this.origins)
        {
            if (r.organizationalHierarchy != null && r.organizationalHierarchy.equals(org))
            {
                result.add(r);
            }
        }

        return result;
    }

    public synchronized List<OriginRecord> findByLocation(final String location)
    {
        if (location == null) return new ArrayList<OriginRecord>();

        List<OriginRecord> result = new ArrayList<OriginRecord>();

        for (OriginRecord r : this.origins)
        {
            if (r.location != null && r.location.equals(location))
            {
                result.add(r);
            }
        }

        return result;
    }

    public synchronized List<OriginRecord> getAll()
    {
        return new ArrayList<OriginRecord>(this.origins);
    }

    public synchronized Integer size()
    {
        return this.origins.size();
    }

    public synchronized void clear()
    {
        this.origins.clear();
    }
}
